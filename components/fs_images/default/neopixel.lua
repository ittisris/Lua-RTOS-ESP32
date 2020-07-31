-- neopixel.lua
thread.start(function()
  neo = neopixel.attach(neopixel.WS2812B, pio.GPIO27, 25)

  pixel = 0
  direction = 0

  while true do
    neo:setPixel(pixel, 252 - (10 * pixel), (10 * pixel), 252 - (10 * pixel))
    neo:update()
    tmr.delayms(100)
    neo:setPixel(pixel, 0, 0, 0)

    if (direction == 0) then
      if (pixel == 25) then
        direction = 1
        pixel = 1
      else
        pixel = pixel + 1
      end
    else
      if (pixel == 0) then
        direction = 0
        pixel = 1
      else
        pixel = pixel - 1
      end
    end
  end
end)