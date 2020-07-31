/** \mainpage
*
****************************************************************************
* Copyright (C) 2015 - 2016 Bosch Sensortec GmbH
*
* File : lm73.h
*
* Date : 2016/07/04
*
* Revision : 2.0.5(Pressure and Temperature compensation code revision is 1.1
*               and Humidity compensation code revision is 1.0)
*
* Usage: Sensor Driver for LM73 sensor
*
****************************************************************************
*
* \section License
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions are met:
*
*   Redistributions of source code must retain the above copyright
*   notice, this list of conditions and the following disclaimer.
*
*   Redistributions in binary form must reproduce the above copyright
*   notice, this list of conditions and the following disclaimer in the
*   documentation and/or other materials provided with the distribution.
*
*   Neither the name of the copyright holder nor the names of the
*   contributors may be used to endorse or promote products derived from
*   this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
* CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
* IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
* DISCLAIMED. IN NO EVENT SHALL COPYRIGHT HOLDER
* OR CONTRIBUTORS BE LIABLE FOR ANY
* DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
* OR CONSEQUENTIAL DAMAGES(INCLUDING, BUT NOT LIMITED TO,
* PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
* LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
* HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
* (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
* ANY WAY OUT OF THE USE OF THIS
* SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE
*
* The information provided is believed to be accurate and reliable.
* The copyright holder assumes no responsibility
* for the consequences of use
* of such information nor for any infringement of patents or
* other rights of third parties which may result from its use.
* No license is granted by implication or otherwise under any patent or
* patent rights of the copyright holder.
**************************************************************************/
/*! \file lm73.h
    \brief LM73 Sensor Driver Support Header File */
#ifndef __LM73_H__
#define __LM73_H__

/************************************************/
#include <stdint.h>
#include <drivers/sensor.h>
/************************************************/

typedef enum
{
	LM73_RESOLUTION_11BIT = 0b00000000,
	LM73_RESOLUTION_12BIT = 0b00100000,
	LM73_RESOLUTION_13BIT = 0b01000000,
	LM73_RESOLUTION_14BIT = 0b01100000
} LM73_resolution_t;

typedef enum
{
	LM73_POWER_ON  = 0b00000000,
	LM73_POWER_OFF = 0b10000000,
} LM73_power_t;

// Config reg bits
#define LM73_BIT_ONE_SHOT		0x04

// Control/status reg bits
#define LM73_BIT_ALRT_STAT		0x08
#define LM73_BIT_THI_FLAG		0x04
#define LM73_BIT_TLOW_FLAG		0x02
#define LM73_BIT_DAV_FLAG		0x01

//#define LM73_BIT_STATUS			0x0F

// Registers
#define LM73_REG_TEMPERATURE	0x00
#define LM73_REG_CONFIG			0x01
#define LM73_REG_THI			0x02
#define LM73_REG_TLOW			0x03
#define LM73_REG_CTRLSTATUS		0x04
#define LM73_REG_ID				0x05

// Register masks
// Config
#define LM73_MASK_PD			~(LM73_POWER_OFF | LM73_POWER_ON)
#define LM73_MASK_ALRT_EN		~()
#define LM73_MASK_ALRT_POL		~()
#define LM73_MASK_ALRT_RST		~()

// Control/status
#define LM73_MASK_TO_DIS		~()
#define LM73_MASK_RESOLUTION	~(LM73_RESOLUTION_11BIT | LM73_RESOLUTION_12BIT | LM73_RESOLUTION_13BIT | LM73_RESOLUTION_14BIT)

driver_error_t *lm73_presetup(sensor_instance_t *unit);
driver_error_t *lm73_setup(sensor_instance_t *unit);
driver_error_t *lm73_acquire(sensor_instance_t *unit, sensor_value_t *values);
driver_error_t *lm73_set(sensor_instance_t *unit, const char *id, sensor_value_t *property);
driver_error_t *lm73_get(sensor_instance_t *unit, const char *id, sensor_value_t *property);

int lm73_get_mode(sensor_instance_t *unit, char *buf);

#endif
