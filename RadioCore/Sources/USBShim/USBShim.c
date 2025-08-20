#include "include/USBShim.h"
#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/usb/IOUSBLib.h>

// 내부적으로 사용하는 USB 장치 핸들 구조체 (외부에는 노출되지 않음)
typedef struct usb_shim_device {
    io_service_t device_service;
    IOUSBDeviceInterface **device;
    IOUSBInterfaceInterface **interface;
    UInt8 interrupt_in_pipe;
} usb_shim_device;

// 레지스트리에서 읽은 장치가 주어진 매칭 조건과 일치하는지 검사합니다.
static int matches_criteria(io_service_t service, const usb_shim_match_criteria *criteria) {
    CFTypeRef vidRef = IORegistryEntryCreateCFProperty(service, CFSTR(kUSBVendorID), kCFAllocatorDefault, 0);
    CFTypeRef pidRef = IORegistryEntryCreateCFProperty(service, CFSTR(kUSBProductID), kCFAllocatorDefault, 0);
    if (!vidRef || !pidRef) {
        if (vidRef) CFRelease(vidRef);
        if (pidRef) CFRelease(pidRef);
        return 0;
    }
    uint32_t vid = 0, pid = 0;
    CFNumberGetValue((CFNumberRef)vidRef, kCFNumberSInt32Type, &vid);
    CFNumberGetValue((CFNumberRef)pidRef, kCFNumberSInt32Type, &pid);
    CFRelease(vidRef);
    CFRelease(pidRef);
    if (vid != criteria->vendor_id) return 0;
    for (size_t i = 0; i < criteria->product_ids_count; ++i) {
        if (pid == criteria->product_ids[i]) return 1;
    }
    return 0;
}

// IOService로부터 IOUSBDeviceInterface를 생성합니다.
static int create_device_interface(io_service_t service, IOUSBDeviceInterface ***device) {
    IOCFPlugInInterface **plugInInterface = NULL;
    SInt32 score = 0;
    kern_return_t kr = IOCreatePlugInInterfaceForService(service, kIOUSBDeviceUserClientTypeID,
                                                         kIOCFPlugInInterfaceID, &plugInInterface, &score);
    if ((kr != kIOReturnSuccess) || !plugInInterface) {
        return -1;
    }
    HRESULT res = (*plugInInterface)->QueryInterface(plugInInterface, CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID), (LPVOID*)device);
    (*plugInInterface)->Release(plugInInterface);
    if (res || !(*device)) {
        return -2;
    }
    return 0;
}

// 조건에 맞는 첫 번째 USB 장치를 찾아 엽니다.
void* usb_open_first(const usb_shim_match_criteria *criteria) {
    CFMutableDictionaryRef matchingDict = IOServiceMatching(kIOUSBDeviceClassName);
    if (!matchingDict) return NULL;
    io_iterator_t iterator = 0;
    kern_return_t kr = IOServiceGetMatchingServices(kIOMainPortDefault, matchingDict, &iterator);
    if (kr != kIOReturnSuccess) return NULL;

    io_service_t service;
    while ((service = IOIteratorNext(iterator))) {
        if (matches_criteria(service, criteria)) {
            usb_shim_device *dev = (usb_shim_device*)calloc(1, sizeof(usb_shim_device));
            dev->device_service = service;
            if (create_device_interface(service, &dev->device) != 0) {
                IOObjectRelease(service);
                free(dev);
                continue;
            }
            if (!dev->device) { IOObjectRelease(service); free(dev); continue; }
            IOReturn openRes = (*dev->device)->USBDeviceOpen(dev->device);
            if (openRes != kIOReturnSuccess) {
                (*dev->device)->Release(dev->device);
                IOObjectRelease(service);
                free(dev);
                continue;
            }
            IOObjectRelease(iterator); // stop iterating further
            return (void*)dev;
        }
        IOObjectRelease(service);
    }
    IOObjectRelease(iterator);
    return NULL;
}

// 장치를 닫고 자원을 정리합니다.
void usb_close(void *opaque) {
    usb_shim_device *dev = (usb_shim_device*)opaque;
    if (!dev) return;
    if (dev->interface) {
        (*dev->interface)->USBInterfaceClose(dev->interface);
        (*dev->interface)->Release(dev->interface);
    }
    if (dev->device) {
        (*dev->device)->USBDeviceClose(dev->device);
        (*dev->device)->Release(dev->device);
    }
    if (dev->device_service) IOObjectRelease(dev->device_service);
    free(dev);
}

// 표준 Control Transfer 를 수행합니다.
int usb_control_transfer(void *opaque,
                         uint8_t bmRequestType,
                         uint8_t bRequest,
                         uint16_t wValue,
                         uint16_t wIndex,
                         void *data,
                         uint16_t wLength,
                         uint32_t timeout_ms) {
    usb_shim_device *dev = (usb_shim_device*)opaque;
    if (!dev || !dev->device) return -1;
    IOUSBDevRequest req;
    req.bmRequestType = bmRequestType;
    req.bRequest = bRequest;
    req.wValue = wValue;
    req.wIndex = wIndex;
    req.wLength = wLength;
    req.pData = data;
    req.wLenDone = 0;
    IOReturn kr = (*dev->device)->DeviceRequest(dev->device, &req);
    if (kr != kIOReturnSuccess) {
        return -2;
    }
    return (int)req.wLenDone;
}

// 인터페이스 번호로 인터페이스를 찾아 엽니다.
static int open_interface_by_number(usb_shim_device *dev, uint8_t ifnum) {
    IOUSBFindInterfaceRequest request;
    request.bInterfaceClass = kIOUSBFindInterfaceDontCare;
    request.bInterfaceSubClass = kIOUSBFindInterfaceDontCare;
    request.bInterfaceProtocol = kIOUSBFindInterfaceDontCare;
    request.bAlternateSetting = kIOUSBFindInterfaceDontCare;

    io_iterator_t iterator;
    IOReturn kr = (*dev->device)->CreateInterfaceIterator(dev->device, &request, &iterator);
    if (kr != kIOReturnSuccess) return -1;
    io_service_t usbInterface;
    while ((usbInterface = IOIteratorNext(iterator))) {
        IOCFPlugInInterface **plugInInterface = NULL;
        SInt32 score = 0;
        kr = IOCreatePlugInInterfaceForService(usbInterface, kIOUSBInterfaceUserClientTypeID, kIOCFPlugInInterfaceID, &plugInInterface, &score);
        IOObjectRelease(usbInterface);
        if ((kIOReturnSuccess != kr) || !plugInInterface) continue;
        IOUSBInterfaceInterface **intf = NULL;
        HRESULT res = (*plugInInterface)->QueryInterface(plugInInterface, CFUUIDGetUUIDBytes(kIOUSBInterfaceInterfaceID), (LPVOID*)&intf);
        (*plugInInterface)->Release(plugInInterface);
        if (res || !intf) continue;
        UInt8 number = 0;
        (*intf)->GetInterfaceNumber(intf, &number);
        if (number == ifnum) {
            if ((*intf)->USBInterfaceOpen(intf) != kIOReturnSuccess) {
                (*intf)->Release(intf);
                IOObjectRelease(iterator);
                return -2;
            }
            dev->interface = intf;
            IOObjectRelease(iterator);
            return 0;
        } else {
            (*intf)->Release(intf);
        }
    }
    IOObjectRelease(iterator);
    return -3;
}

// Interrupt IN 파이프를 사용할 수 있도록 인터페이스를 열고 파이프 참조를 저장합니다.
int usb_prepare_interrupt_in(void *opaque, uint8_t interface_number) {
    usb_shim_device *dev = (usb_shim_device*)opaque;
    if (!dev) return -1;
    if (dev->interface) {
        (*dev->interface)->USBInterfaceClose(dev->interface);
        (*dev->interface)->Release(dev->interface);
        dev->interface = NULL;
    }
    int rc = open_interface_by_number(dev, interface_number);
    if (rc != 0) return rc;
    // Find first interrupt IN pipe
    UInt8 numEndpoints = 0;
    (*dev->interface)->GetNumEndpoints(dev->interface, &numEndpoints);
    for (UInt8 pipeRef = 1; pipeRef <= numEndpoints; ++pipeRef) {
        UInt8 direction, number, transferType, interval;
        UInt16 maxPacketSize;
        if ((*dev->interface)->GetPipeProperties(dev->interface, pipeRef, &direction, &number, &transferType, &maxPacketSize, &interval) == kIOReturnSuccess) {
            if (transferType == kUSBInterrupt && direction == kUSBIn) {
                dev->interrupt_in_pipe = pipeRef;
                return 0;
            }
        }
    }
    return -4;
}

// Interrupt IN 파이프로부터 데이터를 읽습니다.
int usb_read_interrupt_in(void *opaque, void *buffer, uint32_t length, uint32_t timeout_ms) {
    usb_shim_device *dev = (usb_shim_device*)opaque;
    if (!dev || !dev->interface || dev->interrupt_in_pipe == 0) return -1;
    IOReturn kr = (*dev->interface)->ReadPipeTO(dev->interface, dev->interrupt_in_pipe, buffer, &length, timeout_ms, timeout_ms);
    if (kr != kIOReturnSuccess) return -2;
    return (int)length;
}


