-- gdisplay.lua
gdisplay.attach(gdisplay.ILI9341, gdisplay.LANDSCAPE, false)
dw, dh = gdisplay.getscreensize()
gdisplay.setbackground(gdisplay.BLACK)
gdisplay.setforeground(gdisplay.WHITE)
gdisplay.setfont(gdisplay.FONT_DEJAVU24)
gdisplay.clear()
gdisplay.write({gdisplay.CENTER,gdisplay.CENTER},"Lua-RTOS-ESP32",gdisplay.BLUE)
gdisplay.on()