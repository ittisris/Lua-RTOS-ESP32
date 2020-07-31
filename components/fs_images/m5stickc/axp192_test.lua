M5=require("m5stickc")

gdisplay.attach(gdisplay.ST7735_096, gdisplay.PORTRAIT, true)
gdisplay.setforeground(gdisplay.WHITE)
gdisplay.setbackground(gdisplay.BLACK)
gdisplay.settransp(false)
gdisplay.setwrap(false)

--gdisplay.setfont("/@font/Sinclair_s.fon")
gdisplay.setfont(gdisplay.FONT_LCD)
local line_spacing = gdisplay.getfontheight() + 2
local line = 0

M5.Axp.EnableCoulombcounter()

gdisplay.clear()
gdisplay.write({0, 0 * line_spacing}, "AXP192 test")

while(true) do
    line = 0
    
    local axp = M5.Axp.GetAllData()
    
    print("vbat: " .. axp.Vbat)
    print("icharge: " .. axp.Icharge)
    print("idischg: " .. axp.Idischarge)
    print("Temp: " .. axp.Temp)
    print("Bat_p: " .. axp.Bat_p)
    print("Vin: " .. axp.Vin)
    print("Iin: " .. axp.Iin)
    print("CoIn: " .. axp.CoIn)
    print("CoOut: " .. axp.CoOut)
    print("CoD: " .. axp.CoD)

    if(axp.Idischarge > 60) then
        --M5.Axp.screenBreath(7)
    else
        if(axp.Idischarge < 10) then
            --M5.Axp.screenBreath(11)
        end
    end
    
    line = line + 1
    gdisplay.write({0, line * line_spacing},"vbat:" .. string.format("%1.2f",axp.Vbat) .. "V")
    
    line = line + 1
    gdisplay.write({0, line * line_spacing},"icharge:" .. string.format("%3.0f",axp.Icharge) .."mA")
    
    line = line + 1
    gdisplay.write({0, line * line_spacing},"idischg:" .. string.format("%3.0f", axp.Idischarge) .."mA")
    
    line = line + 1
    gdisplay.write({0, line * line_spacing},"temp:" .. string.format("%2.1f",axp.Temp) .."C")
    
    line = line + 1
    gdisplay.write({0, line * line_spacing},"pbat:" .. string.format("%3.0f",axp.Bat_p) .."mW")
    
    line = line + 1
    gdisplay.write({0, line * line_spacing},"CoIn:" .. string.format("%4d",axp.CoIn))
    
    line = line + 1
    gdisplay.write({0, line * line_spacing},"CoOut:" .. string.format("%4d",axp.CoOut))
    
    line = line + 1
    gdisplay.write({0, line * line_spacing},"CoD:" .. string.format("%4d",axp.CoD))
    
    line = line + 1
    gdisplay.write({0, line * line_spacing},"Vin:" .. string.format("%4.0f",axp.Vin) .."mV")
    
    line = line + 1
    gdisplay.write({0, line * line_spacing},"Iin:" .. string.format("%3.0f",axp.Iin) .."mA")


    tmr.delayms(1000)
end