/*
 * Copyright (C) 2015 - 2018, IBEROXARXA SERVICIOS INTEGRALES, S.L.
 * Copyright (C) 2015 - 2018, Jaume Olivé Petrus (jolive@whitecatboard.org)
 *
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the <organization> nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *     * The WHITECAT logotype cannot be changed, you can remove it, but you
 *       cannot change it in any way. The WHITECAT logotype is:
 *
 *          /\       /\
 *         /  \_____/  \
 *        /_____________\
 *        W H I T E C A T
 *
 *     * Redistributions in binary form must retain all copyright notices printed
 *       to any local or remote output device. This include any reference to
 *       Lua RTOS, whitecatboard.org, Lua, and other copyright notices that may
 *       appear in the future.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Lua RTOS, HT16K33 16x8 graphic driver
 * Itti Srisumalai
 *
 */
 
#include "sdkconfig.h"

#if CONFIG_LUA_RTOS_LUA_USE_GDISPLAY
#if CONFIG_LUA_RTOS_FIRMWARE_KIDBRIGHT32

#include "freertos/FreeRTOS.h"

#include <string.h>

#include <sys/delay.h>
#include <sys/driver.h>
#include <sys/syslog.h>

#include <gdisplay/gdisplay.h>

#include <drivers/kidbright32.h>
#include <drivers/ht16k33.h>
#include <drivers/ht16k33_16x8.h>
#include <drivers/gpio.h>
#include <drivers/i2c.h>

#include <drivers/gdisplay.h>

static const unsigned char BitTrans[] = 
{
	0x00, 0x08, 0x04, 0x0C, 0x02, 0x0A, 0x06, 0x0E, 0x01, 0x09, 0x05, 0x0D, 0x03, 0x0B, 0x07, 0x0F
};

static uint8_t contrast=0x00;

/*
 * Helper functions
 */
static driver_error_t *ht16k33_command(int device, uint8_t command) {
	gdisplay_caps_t *caps = gdisplay_ll_get_caps();
	driver_error_t *error;

	int transaction = I2C_TRANSACTION_INITIALIZER;
	uint8_t buff[1];
	buff[0] = command;

	error = i2c_start(device, &transaction);if (error) return error;
	error = i2c_write_address(device, &transaction, caps->address, 0);if (error) return error;
	error = i2c_write(device, &transaction, (char *)&buff, 1);if (error) return error;
	error = i2c_stop(device, &transaction);if (error) return error;

	return NULL;
}

/*
 * Operation functions
 */
void ht16k33_ll_clear() {
	uint8_t *buff = (uint8_t *)gdisplay_ll_get_buffer();
	uint32_t buff_size = gdisplay_ll_get_buffer_size();
	gdisplay_caps_t *caps = gdisplay_ll_get_caps();

	memset(buff,0x00,sizeof(uint8_t) * buff_size);
	ht16k33_update(0,0, caps->width - 1,caps->height - 1 , buff);
}

driver_error_t *ht16k33_init(uint8_t chip, uint8_t orient, uint8_t address) {
	gdisplay_caps_t *caps = gdisplay_ll_get_caps();
	driver_error_t *error;

	caps->addr_window = ht16k33_addr_window;
	caps->on = ht16k33_on;
	caps->off = ht16k33_off;
	caps->invert = ht16k33_invert;
	caps->orientation = ht16k33_set_orientation;
	caps->touch_get = NULL;
	caps->touch_cal = NULL;
	caps->bytes_per_pixel = 0;
	caps->rdepth = 0;
	caps->gdepth = 0;
	caps->bdepth = 0;
	caps->phys_width = 16;
	caps->phys_height = 8;
	caps->width = caps->phys_width;
	caps->height = caps->phys_height;
	caps->interface = GDisplayI2CInterface;
	caps->monochrome_white = 1;

	if (address == 0) {
		caps->address = HT16K33_ONBOARD_ADDR;
	} else{
		caps->address = address;
	}

	// Store chipset
	caps->chipset = chip;

	// Attach to I2C
	if ((error = i2c_attach(CONFIG_LUA_RTOS_GDISPLAY_I2C, I2C_MASTER, 400000, 0, 0, &caps->device))) {
		goto i2c_error;
	}

	error = ht16k33_command(caps->device,0x21);if (error) goto i2c_error;

	// Default brightness
	error = ht16k33_command(caps->device,HT16K33_CMD_BRIGHTNESS | 1);if (error) goto i2c_error;

	delay(100);

	// Allocate buffer
	if (!gdisplay_ll_allocate_buffer((caps->width * caps->height) / 8)) {
		return driver_error(GDISPLAY_DRIVER, GDISPLAY_ERR_NOT_ENOUGH_MEMORY, NULL);
	}

	// Clear display
	ht16k33_ll_clear();
	error = ht16k33_command(caps->device, HT16K33_BLINK_CMD | HT16K33_BLINK_DISPLAYON | (HT16K33_BLINK_OFF << 1));if (error) goto i2c_error;

	syslog(LOG_INFO, "HT16K33 16x8 at i2c%d", CONFIG_LUA_RTOS_GDISPLAY_I2C);

	ht16k33_set_orientation(LANDSCAPE);

	return NULL;

i2c_error:
	return error;
}

void ht16k33_addr_window(uint8_t write, int x0, int y0, int x1, int y1) {
}

void ht16k33_update(int x0, int y0, int x1, int y1, uint8_t *buffer) {
	uint8_t *dst = (buffer?buffer:gdisplay_ll_get_buffer());
	gdisplay_caps_t *caps = gdisplay_ll_get_caps();
	driver_error_t *error;
	
	uint8_t b[16];
	uint8_t i;
	for (i = 0; i < 8; i++) {
		b[ i*2   ]     = contrast ^ ((BitTrans[dst[i  ] & 0x0F] << 4) + BitTrans[dst[i  ] >> 4]);
		b[(i*2)+1]     = contrast ^ ((BitTrans[dst[i+8] & 0x0F] << 4) + BitTrans[dst[i+8] >> 4]);
	}

	int transaction = I2C_TRANSACTION_INITIALIZER;
	uint8_t buff[1];
	buff[0] = HT16K33_COM0;

	error = i2c_start(caps->device, &transaction);if (error) goto i2c_error;
	error = i2c_write_address(caps->device, &transaction, caps->address, 0);if (error) goto i2c_error;
	error = i2c_write(caps->device, &transaction, (char *)buff, 1);if (error) goto i2c_error;
	error = i2c_write(caps->device, &transaction, (char *)b, 16);if (error) goto i2c_error;
	error = i2c_stop(caps->device, &transaction);if (error) goto i2c_error;
	return;

i2c_error:
	return;
}

void ht16k33_set_orientation(uint8_t orientation) {
	gdisplay_caps_t *caps = gdisplay_ll_get_caps();

	caps->orient = orientation;

	if ((caps->orient == LANDSCAPE) || (caps->orient == LANDSCAPE_FLIP)) {
		caps->width = caps->phys_width;
		caps->height = caps->phys_height;
	} else {
		caps->width = caps->phys_height;
		caps->height = caps->phys_width;
	}
}

void ht16k33_on() {
	gdisplay_caps_t *caps = gdisplay_ll_get_caps();
  
  	ht16k33_command(caps->device, HT16K33_BLINK_CMD | HT16K33_BLINK_DISPLAYON | (HT16K33_BLINK_OFF << 1));
}

void ht16k33_off() {
	gdisplay_caps_t *caps = gdisplay_ll_get_caps();

	ht16k33_command(caps->device, HT16K33_BLINK_CMD | (HT16K33_BLINK_OFF << 1));
}

void ht16k33_invert(uint8_t on) {
	gdisplay_caps_t *caps = gdisplay_ll_get_caps();

	contrast=(on?0xFF:00);
	ht16k33_update(0, 0, 0, 0, 0);
}

#endif
#endif
