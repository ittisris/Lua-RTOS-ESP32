local M={}
local D={}
local _axp=nil


local function GetCoulombchargeData()
    local buf, buf1, buf2, buf3
    
	_axp:start()
	_axp:address(0x34, false)
	_axp:write(0xB0)
	_axp:start()
	_axp:address(0x34, true)
	buf = _axp:read()

	_axp:start()
	_axp:address(0x34, false)
	_axp:write(0xB1)
	_axp:start()	
	_axp:address(0x34, true)
	buf1 = _axp:read()

	_axp:start()
	_axp:address(0x34, false)
	_axp:write(0xB2)
	_axp:start()	
	_axp:address(0x34, true)
	buf2 = _axp:read()

	_axp:start()
	_axp:address(0x34, false)
	_axp:write(0xB3)
	_axp:start()
	_axp:address(0x34, true)
	buf3 = _axp:read()
	_axp:stop()

	--coin
  	return (buf << 24) + (buf1 << 16) + (buf2 << 8) + buf3
end


local function GetCoulombdischargeData()
    local buf, buf1, buf2, buf3
    
	_axp:start()
	_axp:address(0x34, false)
	_axp:write(0xB4)
	_axp:start()
	_axp:address(0x34, true)
	buf = _axp:read()
	
	_axp:start()
	_axp:address(0x34, false)
	_axp:write(0xB5)
	_axp:start()
	_axp:address(0x34, true)
	buf1 = _axp:read()
	
	_axp:start()
	_axp:address(0x34, false)
	_axp:write(0xB6)
	_axp:start()
	_axp:address(0x34, true)
	buf2 = _axp:read()

	_axp:start()
	_axp:address(0x34, false)
	_axp:write(0xB7)
	_axp:start()
	_axp:address(0x34, true)
	buf3 = _axp:read()
	_axp:stop()

    --coout
    return (buf << 24) + (buf1 << 16) + (buf2 << 8) + buf3
end


local function GetVbatData()
    local buf, buf1, buf2, buf3
    
	_axp:start()
	_axp:address(0x34, false)
	_axp:write(0x78)
	_axp:start()
	_axp:address(0x34, true)
	buf = _axp:read()
	
	_axp:start()
	_axp:address(0x34, false)
	_axp:write(0x79)
	_axp:start()
	_axp:address(0x34, true)
	buf2 = _axp:read()
	_axp:stop()
	
	--vbat
    return ((buf << 4) + buf2)
end


local function GetVinData()
    local buf, buf1, buf2, buf3
    
	_axp:start()
	_axp:address(0x34, false)
	_axp:write(0x56)
	_axp:start()
	_axp:address(0x34, true)
	buf = _axp:read()
	
	_axp:start()
	_axp:address(0x34, false)
	_axp:write(0x57)
	_axp:start()
	_axp:address(0x34, true)
	buf2 = _axp:read()
	_axp:stop()
	
    --vin
    return (buf << 4) + buf2
end


local function GetIinData()
    local buf, buf1, buf2, buf3
    
	_axp:start()
	_axp:address(0x34, false)
	_axp:write(0x58)
	_axp:start()
	_axp:address(0x34, true)
	buf = _axp:read()
	
	_axp:start()
	_axp:address(0x34, false)
	_axp:write(0x59)
	_axp:start()
	_axp:address(0x34, true)
	buf2 = _axp:read()
	_axp:stop()
	
    --iin
    return (buf << 4) + buf2
end


local function GetIchargeData()
    local buf, buf1, buf2, buf3
    
	_axp:start()
	_axp:address(0x34, false)
	_axp:write(0x7a)
	_axp:start()
	_axp:address(0x34, true)
	buf = _axp:read()
	
	_axp:start()
	_axp:address(0x34, false)
	_axp:write(0x7b)
	_axp:start()
	_axp:address(0x34, true)
	buf2 = _axp:read()
	_axp:stop()
	
	--Icharge
    return (buf << 5) + buf2
end


local function GetIdischargeData()
    local buf, buf1, buf2, buf3
    
	_axp:start()
	_axp:address(0x34, false)
	_axp:write(0x7c)
	_axp:start()
	_axp:address(0x34, true)
	buf = _axp:read()
	
	_axp:start()
	_axp:address(0x34, false)
	_axp:write(0x7d)
	_axp:start()
	_axp:address(0x34, true)
	buf2 = _axp:read()
	_axp:stop()
	
    --idischarge
    return (buf << 5) + buf2
end


local function GetTempData()
    local buf, buf1, buf2, buf3
    
	_axp:start()
	_axp:address(0x34, false)
	_axp:write(0x5e)
	_axp:start()
	_axp:address(0x34, true)
	buf = _axp:read()
	
	_axp:start()
	_axp:address(0x34, false)
	_axp:write(0x5f)
	_axp:start()
	_axp:address(0x34, true)
	buf2 = _axp:read()
	_axp:stop()
	
    --temp
    return (buf << 4) + buf2
end


local function GetPowerbatData()
    local buf, buf1, buf2, buf3
    
	_axp:start()
	_axp:address(0x34, false)
	_axp:write(0x70)
	_axp:start()
	_axp:address(0x34, true)
	buf = _axp:read()
	
	_axp:start()
	_axp:address(0x34, false)
	_axp:write(0x71)
	_axp:start()
	_axp:address(0x34, true)
	buf1 = _axp:read()
	
	_axp:start()
	_axp:address(0x34, false)
	_axp:write(0x72)
	_axp:start()
	_axp:address(0x34, true)
	buf2 = _axp:read()
	_axp:stop()
	
    --power
    return (buf << 16) + (buf1 << 8) + buf2
end


function M.screenBreath(brightness)
	_axp:start()
	_axp:address(0x34, false)
	_axp:write(0x28)
	_axp:write((brightness & 0x0F)  << 4) --Enable LDO2&LDO3, LED&TFT 3.3V
	_axp:stop()
end


function M.EnableCoulombcounter()
	_axp:start()
	_axp:address(0x34, false)
	_axp:write(0xB8, 0x80)
	_axp:stop()
end


function M.DisableCoulombcounter()
	_axp:start()
	_axp:address(0x34, false)
	_axp:write(0xB8, 0x00)
	_axp:stop()
end


function M.StopCoulombcounter()
	_axp:start()
	_axp:address(0x34, false)
	_axp:write(0xB8, 0xC0)
	_axp:stop()
end


function M.ClearCoulombcounter()    
	_axp:start()
	_axp:address(0x34, false)
	_axp:write(0xB8, 0xA0)
	_axp:stop()
end


function M.GetAllData()
	D.Vbat      	= GetVbatData() * 1.1 / 1000
    D.Icharge 		= GetIchargeData() / 2
    D.Idischarge	= GetIdischargeData() / 2
    D.Temp      	= -144.7 + GetTempData() * 0.1
    D.Bat_p     	= GetPowerbatData() * 1.1 * 0.5 /1000
    D.Vin       	= GetVinData() * 1.7
    D.Iin       	= GetIinData() * 0.625
    D.CoIn			= GetCoulombchargeData()
    D.CoOut			= GetCoulombdischargeData()
    D.CoD 			= 65536.0 * 0.5 * (D.CoIn - D.CoOut) / 3600.0 / 25.0
    M.Data = D
    return D
end

-- Init
local function init(i2cn)
    try(
		function()
			if (_axp == nil) then
				_axp = i2c.attach(i2cn, i2c.MASTER, 100000)
			end
			_axp:setspeed(100000)
		end,
		function(where, line, err, message)
			print(1, err, message)
		end
	)

    if (_axp == nil) then
        return nil
    else
    	--//OLED_VPP Enable
    	_axp:start()
    	_axp:address(0x34, false)
    	_axp:write(0x10, 0xff)
    	_axp:stop()
    
    	--//Enable LDO2&LDO3, LED&TFT 3.3V
    	_axp:start()
    	_axp:address(0x34, false)
    	_axp:write(0x28)
    	-- Screenbright = 11 << 4
    	_axp:write(0xB0)
    	_axp:stop()
    
    	--//Enable all the ADCs   
    	_axp:start()
    	_axp:address(0x34, false)
    	_axp:write(0x82, 0xff)
    	_axp:stop()
    
    	--//Enable Charging, 100mA, 4.2V, End at 0.9
    	_axp:start()
    	_axp:address(0x34, false)
    	_axp:write(0x33, 0xC0)
    	_axp:stop()
    
    	--//Enable Colume Counter
    	_axp:start()
    	_axp:address(0x34, false)
    	_axp:write(0xB8, 0x80)
    	_axp:stop()
    
    	--//Enable DC-DC1, OLED_VDD, 5B V_EXT
    	_axp:start()
    	_axp:address(0x34, false)
    	_axp:write(0x12, 0x4d)
    	_axp:stop()
    
    	--//PEK
    	_axp:start()
    	_axp:address(0x34, false)
    	_axp:write(0x36, 0x5c)
    	_axp:stop()
    
    	--//gpio0
    	_axp:start()
    	_axp:address(0x34, false)
    	_axp:write(0x90, 0x02)
    	_axp:stop()
      
      	return M
    end
end

return init