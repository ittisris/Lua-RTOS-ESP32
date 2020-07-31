-- neopixel.lua
thread.start(function()
  neo = neopixel.attach(neopixel.WS2812B, pio.GPIO15, 10)

  pixel = 0
  direction = 0

  while true do
    neo:setPixel(pixel, 252 - (28 * pixel), (28 * pixel), 252 - (28 * pixel))
    neo:update()
    tmr.delayms(100)
    neo:setPixel(pixel, 0, 0, 0)

    if (direction == 0) then
      if (pixel == 9) then
        direction = 1
        pixel = 8
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