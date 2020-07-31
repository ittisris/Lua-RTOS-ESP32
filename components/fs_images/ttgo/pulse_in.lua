--pulse_in.lua

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
pio.pin.setdir(pio.INPUT, pio.IN1)
pio.pin.setpull(pio.PULLUP, pio.IN1)
pio.pin.interrupt(pio.IN1, function()
        mtx:lock()
        cnt = cnt + 1
        mtx:unlock()
        
        if( (cnt % 5) == 0) then
            pio.pin.setval(0, pio.IOT_LED)
            --pio.pin.inv(pio.IOT_LED)
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
    local freq = 0
    local f0 = -1
    while(true) do
        mtx:lock()
        freq = cnt
        cnt = 0
        mtx:unlock()
        if( freq ~= f0) then
            c0 = c
            gdisplay.off()
            gdisplay.clear()
            gdisplay.write({gdisplay.RIGHT,0}, freq)
            gdisplay.on()
        end
        tmr.delayms(1000)
    end
end)