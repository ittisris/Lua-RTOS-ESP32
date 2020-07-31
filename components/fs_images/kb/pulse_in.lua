-- pulse_in.lua
-- Itti Srisumalai 2019

local cnt=0
mtx = thread.createmutex()

gdisplay.attach(gdisplay.HT16K33_16_8, gdisplay.LANDSCAPE, true)
gdisplay.setfont(gdisplay.FONT_LCD)
gdisplay.setwrap(false)
gdisplay.setfixed(true)

-- click-sound
pio.pin.setdir(pio.OUTPUT, pio.SPRK)
pio.pin.setpull(pio.NOPULL, pio.SPRK)

-- pulse pin
-- Itti Srisumalai 2019

pio.pin.setdir(pio.INPUT, pio.IN1)
pio.pin.setpull(pio.PULLUP, pio.IN1)
pio.pin.interrupt(pio.IN1, function()
        mtx:lock()
        cnt = cnt + 1
        mtx:unlock()
        
        if( (cnt % 5) == 0) then
            pio.pin.setval(0, pio.IOT_LED)
        end
        pio.pin.inv(pio.SPRK)
        
end, pio.pin.IntrPosEdge)

-- LED timer
thread.start(function()
    while(true) do
        tmr.delayms(10)
        mtx:lock()
        pio.pin.setval(1, pio.IOT_LED)
        mtx:unlock()
    end
end)

-- display loop every 1000 milliseconds
thread.start(function()
    local f1 = 0
    local f0 = -1
    local t=os.time()
    while(true) do
        while(os.time() <= t) do
            tmr.delayms(1)
        end
        mtx:lock()
        f1 = cnt
        cnt = 0
        t=os.time()
        mtx:unlock()
        if( f1 ~= f0) then
            f0=f1
            gdisplay.clear()
            gdisplay.write({gdisplay.RIGHT,0}, f0)
        end
    end
end)
