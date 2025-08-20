#ifndef USBShim_h
#define USBShim_h

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

// Swift 상호 운용을 단순화하기 위해 장치 핸들을 void* 타입의 불투명 포인터로 노출합니다.

// 장치 검색을 위한 매칭 조건입니다.
// 특정 벤더 ID와 하나 이상의 제품 ID 목록으로 필터링합니다.
typedef struct {
    uint16_t vendor_id;                 // USB 벤더 ID (예: 삼성 0x04e8)
    const uint16_t *product_ids;        // 허용되는 제품 ID 배열 포인터
    size_t product_ids_count;           // 제품 ID 개수
} usb_shim_match_criteria;

// 매칭 조건에 부합하는 첫 번째 USB 장치를 엽니다.
// 실패 시 NULL을 반환합니다.
void* usb_open_first(const usb_shim_match_criteria *criteria);

// 장치를 닫고 자원을 해제합니다.
void usb_close(void *dev);

// 장치 레벨 제어 전송(Control Transfer)을 수행합니다.
// 성공 시 전송된 바이트 수를, 실패 시 음수를 반환합니다.
int usb_control_transfer(void *dev,
                         uint8_t bmRequestType,
                         uint8_t bRequest,
                         uint16_t wValue,
                         uint16_t wIndex,
                         void *data,
                         uint16_t wLength,
                         uint32_t timeout_ms);

// 지정한 인터페이스 번호를 열고 첫 번째 Interrupt IN 파이프를 캐시합니다.
// 성공 시 0을 반환합니다.
int usb_prepare_interrupt_in(void *dev, uint8_t interface_number);

// 캐시된 Interrupt IN 파이프에서 데이터를 읽습니다.
// 성공 시 읽은 바이트 수를, 실패 시 음수를 반환합니다.
int usb_read_interrupt_in(void *dev, void *buffer, uint32_t length, uint32_t timeout_ms);

#ifdef __cplusplus
}
#endif

#endif /* USBShim_h */


