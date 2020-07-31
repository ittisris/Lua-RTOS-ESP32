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
 * Lua RTOS, ILI9341 driver
 *
 */

/*
 * This driver is inspired and takes code from the following projects:
 *
 * Boris Lovošević, tft driver for Lua RTOS:
 *
 * https://github.com/loboris/Lua-RTOS-ESP32-lobo/tree/master/components/lua_rtos/Lua/modules/screen
 *
 */

#include "sdkconfig.h"

#if CONFIG_LUA_RTOS_LUA_USE_GDISPLAY

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

#include <string.h>

#include <sys/driver.h>
#include <sys/syslog.h>

#include <gdisplay/gdisplay.h>

#include <drivers/gpio.h>
#include <drivers/gdisplay.h>

#include "neopixel.h"
#include "neopixel_5x5.h"
#include <machine/endian.h>

// Current chipset
static uint8_t on = 1;
static uint8_t invert = 0;

static uint32_t unit;
/*
 * Helper functions
 */

/*
 * Operation functions
 */

driver_error_t *neopixel5x5_init(uint8_t chip, uint8_t orientation, uint8_t address) {
	driver_error_t *error;
	gdisplay_caps_t *caps = gdisplay_ll_get_caps();

	caps->addr_window = neopixel5x5_addr_window;
	caps->on = neopixel5x5_on;
	caps->off = neopixel5x5_off;
	caps->invert = neopixel5x5_invert;
	caps->orientation = neopixel5x5_set_orientation;
	caps->touch_get = NULL;
	caps->touch_cal = NULL;
	caps->bytes_per_pixel = 2;
	caps->rdepth = 5;
	caps->gdepth = 6;
	caps->bdepth = 5;
	caps->phys_width  = 5;
	caps->phys_height = 5;
	caps->width = caps->phys_width;
	caps->height = caps->phys_height;
	caps->interface = GDisplayI2CInterface;

	// Store chipset
	caps->chipset = chip;

	//address=GPIO
	if (address == 0) {
		caps->address = NEOPIXEL5X5_GPIO;
	} else{
		caps->address = address;
	}

    // Init
	if (caps->device == -1)
		if ((error = neopixel_setup(NeopixelWS2812B, (address?address:NEOPIXEL5X5_GPIO), NEOPIXEL5X5_PIXELS, &unit)))
    		return error;

	neopixel5x5_set_orientation(LANDSCAPE);

	// Allocate buffer
	if (!gdisplay_ll_allocate_buffer((caps->phys_width * caps->phys_width))) 
		return driver_error(GDISPLAY_DRIVER, GDISPLAY_ERR_NOT_ENOUGH_MEMORY, NULL);

    // Clear screen (black)
    neopixel5x5_clear();

	syslog(LOG_INFO, "Neopixel 5x5 @GPIO%d", caps->address);

    return NULL;
}

void neopixel5x5_update(int x0, int y0, int x1, int y1, uint8_t *buffer) {
	driver_error_t *error;
	gdisplay_caps_t *caps = gdisplay_ll_get_caps();
	//uint32_t buff_size = gdisplay_ll_get_buffer_size();
	uint16_t *buff = (uint16_t *)(buffer?buffer:gdisplay_ll_get_buffer());

	uint32_t color;
	int p,r,g,b;
    uint8_t i,j,k;

	//syslog(LOG_DEBUG, "x0= %d x1= %d y0= %d y1= %d \n", x0,x1,y0,y1);

	k=0;
	for(i=x0;i <= x1;i++) {
		for(j=y0;j<=y1;j++){
			p=(i*caps->width )+j;

			color = buff[k];
			k++;

			if (BYTE_ORDER == LITTLE_ENDIAN) {
				uint32_t wd;
				wd = (uint32_t)(color >> 8);
				wd |= (uint32_t)(color & 0xff) << 8;
				color = wd;
			}	

			//syslog(LOG_DEBUG, "p= %d color= %08x", p,color);

			b = ((~(0xffffffff << caps->bdepth) & color) << (8 - caps->bdepth));
			color >>= caps->bdepth;
			g = ((~(0xffffffff << caps->gdepth) & color) << (8 - caps->gdepth));
			color >>= caps->gdepth;
			r = ((~(0xffffffff << caps->rdepth) & color) << (8 - caps->rdepth));

			//syslog(LOG_DEBUG, "r= %d g= %d b= %d\n", r,g,b);

			if ((error = neopixel_rgb(unit, p, r, g, b)))
				;
		}
	}

    if ((error = neopixel_update(unit)))	//unit
    	;
}

void neopixel5x5_addr_window(uint8_t write, int x0, int y0, int x1, int y1) {
	//syslog(LOG_DEBUG, "add_windows x0= %d x1= %d y0= %d y1= %d \n", x0,x1,y0,y1);
}

void neopixel5x5_set_orientation(uint8_t orientation) {
	gdisplay_caps_t *caps = gdisplay_ll_get_caps();
	caps->orient = orientation;
	caps->width = caps->phys_height;
	caps->height = caps->phys_width;
	caps->xstart = 0;
	caps->ystart = 0;
}

void neopixel5x5_on() {
	on = 1;
}

void neopixel5x5_off() {
	on = 0;
}

void neopixel5x5_invert(uint8_t on) {
	invert = on;
}

void neopixel5x5_clear() {
	uint8_t *buff = (uint8_t *)gdisplay_ll_get_buffer();
	uint32_t buff_size = gdisplay_ll_get_buffer_size();
	gdisplay_caps_t *caps = gdisplay_ll_get_caps();

	memset(buff,0x00, caps->bytes_per_pixel * buff_size);
	neopixel5x5_update(0,0, caps->phys_width - 1,caps->phys_height - 1 , buff);
}

#endif
