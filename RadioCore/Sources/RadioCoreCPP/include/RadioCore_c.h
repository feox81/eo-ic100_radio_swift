#pragma once
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

void* rc_create(void);
void rc_destroy(void*);

void rc_set_power(void*, int on);
int rc_get_power(void*);

void rc_set_recording(void*, int on);
int rc_get_recording(void*);

void rc_set_spacing(void*, uint16_t spacing);
uint8_t rc_get_spacing(void*);

void rc_set_mute(void*, int on);
int rc_get_mute(void*);

void rc_set_volume(void*, uint16_t vol);
uint8_t rc_get_volume(void*);

void rc_set_channel(void*, double mhz);
double rc_get_channel(void*);

uint8_t rc_get_rssi(void*);

#ifdef __cplusplus
}
#endif


