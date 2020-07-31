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
 * Lua RTOS, LM73 sensor (Temperature)
 *
 */

#include "sdkconfig.h"

#if CONFIG_LUA_RTOS_LUA_USE_SENSOR
#if CONFIG_LUA_RTOS_USE_SENSOR_LM73

#include <math.h>
#include <string.h>

#include <sys/driver.h>
#include <sys/delay.h>
#include <sys/syslog.h>

#include <drivers/sensor.h>
#include <drivers/i2c.h>

#include "lm73.h"

#if CONFIG_LUA_RTOS_FIRMWARE_KIDBRIGHT32
#include <drivers/kidbright32.h>
#define LM73_I2C_ADDRESS LM73_1_ONBOARD_ADDR	// Package marking T730=LM73-0 T731=LM73-1
#else
#define LM73_I2C_ADDRESS 0x4d
#endif

driver_error_t *LM73_presetup(sensor_instance_t *unit);
driver_error_t *LM73_acquire(sensor_instance_t *unit, sensor_value_t *values);
driver_error_t *LM73_set(sensor_instance_t *unit, const char *id, sensor_value_t *setting);

// Sensor specification and registration
static const sensor_t __attribute__((used,unused,section(".sensors"))) LM73_sensor = {
	.id = "LM73",
	.interface = {
		{.type = I2C_INTERFACE},
	},
	.data = {
		{.id = "temperature", .type = SENSOR_DATA_DOUBLE},
	},
	.properties = {
		{.id = "resolution", .type = SENSOR_DATA_INT},
		// {.id = "power",.type = SENSOR_DATA_INT},
		// {.id = "alert",.type = SENSOR_DATA_INT},
	},
	.presetup = LM73_presetup,
	.acquire = LM73_acquire,
	.set = LM73_set
};

/*
 * Operation functions
 */
driver_error_t *LM73_presetup(sensor_instance_t *unit) {
	// Set default values, if not provided
	if (unit->setup[0].i2c.devid == 0) {
		unit->setup[0].i2c.devid = LM73_I2C_ADDRESS;
	}

	if (unit->setup[0].i2c.speed == 0) {
		unit->setup[0].i2c.speed = 400000;
	}

	unit->properties[0].integerd.value = 0; // H-Resolution Mode
	//unit->properties[1].integerd.value = 1; // power

	return NULL;
}

driver_error_t *LM73_acquire(sensor_instance_t *unit, sensor_value_t *values) {
	int16_t i2c = unit->setup[0].i2c.id;
	uint8_t address = unit->setup[0].i2c.devid;

	driver_error_t *error;

	int transaction = I2C_TRANSACTION_INITIALIZER;
	uint8_t buff[2];

	// Power on
	buff[0] = LM73_REG_CONFIG;
	buff[1] = LM73_POWER_ON;
	error = i2c_start(i2c, &transaction);if (error) return error;
	error = i2c_write_address(i2c, &transaction, address, 0);if (error) return error;
	error = i2c_write(i2c, &transaction, (char *)buff, 2);if (error) return error;
	error = i2c_stop(i2c, &transaction);if (error) return error;

	delay(100);

	// Set resolution mode
	if        (unit->properties[0].integerd.value == 0) {
		buff[1] = LM73_RESOLUTION_11BIT;
	} else if (unit->properties[0].integerd.value == 1) {
		buff[1] = LM73_RESOLUTION_12BIT;
	} else if (unit->properties[0].integerd.value == 2) {
		buff[1] = LM73_RESOLUTION_13BIT;
	} else if (unit->properties[0].integerd.value == 3) {
		buff[1] = LM73_RESOLUTION_14BIT;
	}

	// set pointer to control/status reg
	buff[0] = LM73_REG_CTRLSTATUS;
	error = i2c_start(i2c, &transaction);if (error) return error;
	error = i2c_write_address(i2c, &transaction, address, 0);if (error) return error;
	error = i2c_write(i2c, &transaction, (char *)buff, 1);if (error) return error;
	error = i2c_stop(i2c, &transaction);if (error) return error;

	// read control/status reg
	error = i2c_start(i2c, &transaction);if (error) return error;
	error = i2c_write_address(i2c, &transaction, address, 1);if (error) return error;
	error = i2c_read(i2c, &transaction, (char *)buff, 1);if (error) return error;
	error = i2c_stop(i2c, &transaction);if (error) return error;
	buff[1] = (buff[0] & LM73_MASK_RESOLUTION) | buff[1];

	// update control/status reg
	buff[0] = LM73_REG_CTRLSTATUS;
	error = i2c_start(i2c, &transaction);if (error) return error;
	error = i2c_write_address(i2c, &transaction, address, 0);if (error) return error;
	error = i2c_write(i2c, &transaction, (char *)buff, 2);if (error) return error;
	error = i2c_stop(i2c, &transaction);if (error) return error;

	// set pointer to temperature reg
	buff[0] = LM73_REG_TEMPERATURE;
	error = i2c_start(i2c, &transaction);if (error) return error;
	error = i2c_write_address(i2c, &transaction, address, 0);if (error) return error;
	error = i2c_write(i2c, &transaction, (char *)buff, 1);if (error) return error;
	error = i2c_stop(i2c, &transaction);if (error) return error;

	// read temperature
	error = i2c_start(i2c, &transaction);if (error) return error;
	error = i2c_write_address(i2c, &transaction, address, 1);if (error) return error;
	error = i2c_read(i2c, &transaction, (char *)buff, 2);if (error) return error;
	error = i2c_stop(i2c, &transaction);if (error) return error;

	values[0].doubled.value = ((buff[0] << 8) + buff[1]) * 0.0078125;	//1C=0000 0000 1000 0000  = 0080h, 1/128 = 0.0078125

	// Power down
	buff[0] = LM73_REG_CONFIG;
	buff[1] = LM73_POWER_OFF;
	error = i2c_start(i2c, &transaction);if (error) return error;
	error = i2c_write_address(i2c, &transaction, address, 0);if (error) return error;
	error = i2c_write(i2c, &transaction, (char *)buff, 2);if (error) return error;
	error = i2c_stop(i2c, &transaction);if (error) return error;

	return NULL;
}

driver_error_t *LM73_set(sensor_instance_t *unit, const char *id, sensor_value_t *setting) {
	if (strcmp(id,"resolution") == 0) {
		if ((setting->integerd.value < 0) || (setting->integerd.value > 3)) {
			return driver_error(SENSOR_DRIVER, SENSOR_ERR_INVALID_VALUE, NULL);
		}

		memcpy(&unit->properties[0], setting, sizeof(sensor_value_t));
	}

	return NULL;
}

#endif
#endif
