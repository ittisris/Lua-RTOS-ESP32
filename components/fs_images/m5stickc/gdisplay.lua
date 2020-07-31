-- gdisplay.lua
M5=require("m5stickc")
gdisplay.attach(gdisplay.ST7735_096, gdisplay.LANDSCAPE, false)
gdisplay.clear()
gdisplay.setfont(gdisplay.FONT_DEJAVU16)
gdisplay.write({gdisplay.CENTER,gdisplay.CENTER},"Lua-RTOS-ESP32", gdisplay.YELLOW)
gdisplay.on()