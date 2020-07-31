--pulse_in.lua
local cnt=0
mtx = thread.createmutex()

gdisplay.attach(gdisplay.ILI9341, gdisplay.LANDSCAPE, false)
gdisplay.setfont("/@font/DotMatrix_M.fon")
gdisplay.settransp(false)
gdisplay.setwrap(false)
gdisplay.setfixed(true)

-- click sound
pio.pin.setdir(pio.OUTPUT, pio.GPIO25)
pio.pin.setpull(pio.NOPULL, pio.GPIO25)

-- pulse pin                        
pio.pin.setdir(pio.INPUT, pio.GPIO35)
pio.pin.setpull(pio.PULLUP, pio.GPIO35)
pio.pin.interrupt(pio.GPIO35, function()
        mtx:lock()
        cnt = cnt + 1
        mtx:unlock()
        pio.pin.inv(pio.GPIO13)
        
end, pio.pin.IntrPosEdge)

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