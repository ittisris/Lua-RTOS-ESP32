-- Sample: LM73 Temperature sensor 
-- LM73 at I2C1 default address

local temperature = 0
local mtx = thread.createmutex()

-- Read
thread.start(function()
    local lm73 = sensor.attach("LM73", i2c.I2C1, 0)
    while(true) do
        mtx:lock()
        temperature=math.floor(lm73:read("temperature") + 0.5)
        print("temperature = "..temperature.."C")
        mtx:unlock()
        tmr.delay(1)
    end
end)

-- Display
thread.start(function()
    gdisplay.attach(gdisplay.HT16K33_16_8)
    gdisplay.setfont(gdisplay.FONT_LCD)
    gdisplay.on()
    while(true) do
        gdisplay.clear()  
        mtx:lock()
        gdisplay.write({gdisplay.RIGHT,gdisplay.CENTER},temperature)
        mtx:unlock()
        tmr.delay(1)
    end
end)
