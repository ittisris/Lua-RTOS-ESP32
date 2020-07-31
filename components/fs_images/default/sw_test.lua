-- sw_test.lua
-- Itti Srisumalai 2019

tone={261.6,293.7,329.6,349.2,392.0,440.0,493.9,523.2}

-- init display
gdisplay.attach(gdisplay.HT16K33_16_8)
gdisplay.setfont(gdisplay.FONT_LCD)
gdisplay.setwrap(false)
gdisplay.write({0,0}, "Switch test")
tmr.delay(1)
gdisplay.clear()

-- Speaker (GPIO13)
sprk = pwm.attach(pio.SPRK, 261, 0)
sprk:start()

f = 0

-- Attach switch to SW1 (GPIO16)
sw1 = sensor.attach("PUSH_SWITCH", pio.SW1)
sw1:callback(function(data)
    if (data.on == 0) then
        print("SW1 Off")
    elseif (data.on == 1) then
        if(f>0) then
            f = f - 1
        end
        print("SW1 On")
    end
end)

-- Attach switch to SW2 (GPIO14)
sw2 = sensor.attach("PUSH_SWITCH", pio.SW2)
sw2:callback(function(data)
    if (data.on == 0) then
        print("SW2 Off")
    elseif (data.on == 1) then
        if(f<8)then
            f = f + 1
        end
        print("SW2 On")
      end
end)

-- Mainloop
f0=0

while(true) do
    tmr.delayms(10)
    if(f0~=f) then
        gdisplay.clear()
        f0=f
        if(f0==0)then
            sprk:setduty(0)
        else
            gdisplay.line(8-f0, 8-f0, 7+f0 , 8-f0, gdisplay.WHITE)
            sprk:setfreq(tone[f0])
            sprk:setduty(50 * 0.01)
        end
    end
end
