--pulse_in.lua
M5=require("m5stickc")

local cnt=0
mtx = thread.createmutex()

gdisplay.attach(gdisplay.ST7735_096, gdisplay.LANDSCAPE, false)
gdisplay.setfont("/@font/DotMatrix_L_Num.fon")
gdisplay.settransp(false)
gdisplay.setwrap(false)
gdisplay.setfixed(true)

-- pulse pin                        
pio.pin.setdir(pio.INPUT, pio.GPIO26)
--pio.pin.setpull(pio.PULLUP, pio.GPIO35)
pio.pin.interrupt(pio.GPIO26, function()
        mtx:lock()
        cnt = cnt + 1
        mtx:unlock()
end, pio.pin.IntrPosEdge)

-- display loop every 1000 milliseconds
thread.start(function()
    local f = 0
    local f0 = -1
    while(true) do
        mtx:lock()
        f = cnt
        cnt = 0
        mtx:unlock()
        if( f ~= f0) then
            gdisplay.write({gdisplay.CENTER,gdisplay.CENTER}, f0 , gdisplay.BLACK)
            f0 = f
            gdisplay.write({gdisplay.CENTER,gdisplay.CENTER}, f , gdisplay.GREEN)
            gdisplay.on()
        end
        tmr.delayms(1000)
    end
end)