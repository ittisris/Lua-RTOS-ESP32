-- gdisplay.lua
gdisplay.attach(gdisplay.ILI9341, gdisplay.LANDSCAPE, false)
gdisplay.clear()
gdisplay.setfont(gdisplay.FONT_DEJAVU24)
gdisplay.write({gdisplay.CENTER,gdisplay.CENTER},"Lua-RTOS-ESP32")
gdisplay.on()