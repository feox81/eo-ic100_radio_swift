#include "include/RadioCore_c.h"
#include "include/RadioCore.hpp"

using rc::BesFM;
using rc::ChannelSpacing;

extern "C" {

void* rc_create(void) { return new BesFM(); }
void rc_destroy(void* p) { delete static_cast<BesFM*>(p); }

void rc_set_power(void* p, int on) { static_cast<BesFM*>(p)->setPower(on != 0); }
int rc_get_power(void* p) { return static_cast<BesFM*>(p)->getPower() ? 1 : 0; }

void rc_set_recording(void* p, int on) { static_cast<BesFM*>(p)->setRecording(on != 0); }
int rc_get_recording(void* p) { return static_cast<BesFM*>(p)->getRecording() ? 1 : 0; }

void rc_set_spacing(void* p, uint16_t spacing) { static_cast<BesFM*>(p)->setChannelSpacing(static_cast<ChannelSpacing>(spacing)); }
uint8_t rc_get_spacing(void* p) { return static_cast<BesFM*>(p)->getChannelSpacing(); }

void rc_set_mute(void* p, int on) { static_cast<BesFM*>(p)->setMute(on != 0); }
int rc_get_mute(void* p) { return static_cast<BesFM*>(p)->getMute() ? 1 : 0; }

void rc_set_volume(void* p, uint16_t vol) { static_cast<BesFM*>(p)->setVolume(vol); }
uint8_t rc_get_volume(void* p) { return static_cast<BesFM*>(p)->getVolume(); }

void rc_set_channel(void* p, double mhz) { static_cast<BesFM*>(p)->setChannel(mhz); }
double rc_get_channel(void* p) { return static_cast<BesFM*>(p)->getChannel(); }

uint8_t rc_get_rssi(void* p) { return static_cast<BesFM*>(p)->getRssi(); }

}


