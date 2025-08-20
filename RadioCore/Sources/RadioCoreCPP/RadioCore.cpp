#include "include/RadioCore.hpp"
#include "USBShim.h"
#include <algorithm>

using namespace rc;

BesFM::BesFM() {
    uint16_t pids[] = {0xa054, 0xa059, 0xa05b};
    usb_shim_match_criteria crit{0x04e8, pids, sizeof(pids)/sizeof(pids[0])};
    dev_ = usb_open_first(&crit);
    if (dev_) {
        (void)usb_prepare_interrupt_in(dev_, 4);
    }
}

BesFM::~BesFM() {
    if (dev_) usb_close(dev_);
}

bool BesFM::isOpen() const { return dev_ != nullptr; }

static inline void set_cmd(void* dev, uint16_t cmd, uint16_t value) {
    uint8_t local[1] = {0};
    usb_control_transfer(dev, 192, 161, cmd, value, local, 1, 1000);
}

static inline uint8_t get_u8(void* dev, uint16_t cmd) {
    uint8_t local[2] = {0};
    usb_control_transfer(dev, 192, 162, cmd, 0, local, 2, 1000);
    return local[0];
}

void BesFM::setPower(bool on) { if (dev_) set_cmd(dev_, 0, on ? 1 : 0); }
bool BesFM::getPower() const { return dev_ ? (get_u8(dev_, 2) != 0) : false; }

void BesFM::setRecording(bool on) { if (dev_) set_cmd(dev_, 14, on ? 1 : 0); }
bool BesFM::getRecording() const { return dev_ ? (get_u8(dev_, 17) != 0) : false; }

void BesFM::setChannelSpacing(ChannelSpacing s) { if (dev_) set_cmd(dev_, 3, static_cast<uint16_t>(s)); }
uint8_t BesFM::getChannelSpacing() const { return dev_ ? get_u8(dev_, 5) : 0; }

void BesFM::setMute(bool on) { if (dev_) set_cmd(dev_, 4, on ? 1 : 0); }
bool BesFM::getMute() const { return dev_ ? (get_u8(dev_, 6) != 0) : false; }

void BesFM::setVolume(uint16_t vol) { if (dev_) set_cmd(dev_, 5, std::min<uint16_t>(15, vol)); }
uint8_t BesFM::getVolume() const { return dev_ ? get_u8(dev_, 8) : 0; }

void BesFM::setChannel(double mhz) { if (dev_) set_cmd(dev_, 9, static_cast<uint16_t>(mhz * 100.0)); }
double BesFM::getChannel() const {
    if (!dev_) return 0.0;
    uint8_t local[2] = {0};
    usb_control_transfer(dev_, 192, 162, 13, 0, local, 2, 1000);
    uint16_t value = static_cast<uint16_t>(local[0]) | (static_cast<uint16_t>(local[1]) << 8);
    return static_cast<double>(value) / 100.0;
}

uint8_t BesFM::getRssi() const { return dev_ ? get_u8(dev_, 4) : 0; }

Status BesFM::getStatus() const {
    Status s{}; s.kind = Status::Kind::Raw;
    if (!dev_) return s;
    uint8_t local[12] = {0};
    int32_t read = usb_control_transfer(dev_, 192, 163, 0, 0, local, 12, 200);
    if (read <= 0) return s;
    switch (local[0]) {
        case 0: s.kind = Status::Kind::Seek; s.success = local[1] != 0; s.freqMHz = (double)((uint16_t)local[2] | ((uint16_t)local[3] << 8)) / 100.0; s.strength = local[4]; break;
        case 1: s.kind = Status::Kind::Tune; s.success = local[1] != 0; s.freqMHz = (double)((uint16_t)local[2] | ((uint16_t)local[3] << 8)) / 100.0; s.strength = local[4]; break;
        case 2: s.kind = Status::Kind::Rds; s.error = local[1]; s.strength = local[2]; s.rds[0]=local[4]; s.rds[1]=local[3]; s.rds[2]=local[6]; s.rds[3]=local[5]; s.rds[4]=local[8]; s.rds[5]=local[7]; s.rds[6]=local[10]; s.rds[7]=local[9]; break;
        default: break;
    }
    return s;
}


