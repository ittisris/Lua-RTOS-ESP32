-- Sample: LM73 Temperature sensor 
-- LM73 at I2C1 default address
-- Itti Srisumalai 2019

local temperature = 0
local mtx = thread.createmutex()

-- Read
thread.start(function()
    local lm73 = sensor.attach("LM73", i2c.I2C1, 0)
    while(true) do
        mtx:lock()
        temperature=math.floor(lm73:read("temperature")+0.5)
        print("Temperature = "..temperature.."C")
        mtx:unlock()
        tmr.delay(1)
    end
end)

-- Display
thread.start(function()
    gdisplay.attach(gdisplay.HT16K33_16_8)
    gdisplay.setfont(gdisplay.FONT_LCD)
    gdisplay.on()

    gdisplay.setorient(gdisplay.PORTRAIT)
    gdisplay.clear()
    gdisplay.write({0,0},"Hello, World!")
    
    gdisplay.setorient(gdisplay.PORTRAIT_FLIP)
    gdisplay.clear()
    gdisplay.write({0,0},"Hello, World!")
    
    gdisplay.setorient(gdisplay.LANDSCAPE_FLIP)
    gdisplay.clear()
    gdisplay.write({0,0},"Hello, World!")
    
    gdisplay.setorient(gdisplay.LANDSCAPE)
    gdisplay.clear()
    gdisplay.write({0,0},"Hello, World!")

    tmr.delayms(500)

    local t=0
    while(true) do
        gdisplay.putpixel({0,0}, gdisplay.WHITE)
        tmr.delayms(100)
        mtx:lock()
        if(t~=temperature) then
            t=temperature
            gdisplay.clear()
            gdisplay.write({0,0},"Temperature")
            gdisplay.clear()
            gdisplay.write({gdisplay.RIGHT,0},t)
        end
        mtx:unlock()
        gdisplay.putpixel({0,0}, gdisplay.BLACK)
        tmr.delayms(1900)
    end
end)