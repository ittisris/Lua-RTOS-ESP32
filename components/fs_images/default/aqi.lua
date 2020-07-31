mtx = thread.createmutex()

-- Air quality index
pm25 = 0.0
temperature = 0.0
cpu_temperature = 0.0
humidity = 0
pressure = 0
SEALEVELPRESSURE_HPA = 1013.25

read_environ = function ()
    bme280 = sensor.attach("BME280", i2c.I2C0, 0x76)
    
    while true do
        tmr.delay(5)
        
        mtx:lock()
        
        -- Read temperature
        temperature = math.floor(bme280:read("temperature") * 10) / 10

        -- Read humidity
        humidity =  math.floor(bme280:read("humidity") * 10) / 10

        -- Read preassure
        pressure = math.floor(bme280:read("pressure") * 10) / 10
         
        mtx:unlock()
        
        -- Print results
        print("Temperature = " .. string.format("%3.1f",temperature) .. " *C")
        print("Humidity = " .. string.format("%2.1f",humidity) .." %")
        print("Pressure = ".. string.format("%4.1f",pressure) .." hPa")
    
        --Equation taken from BMP180 datasheet (page 16):
        --http://www.adafruit.com/datasheets/BST-BMP180-DS000-09.pdf

        --Note that using the equation from wikipedia can give bad results
        --at high altitude. See this thread for more information:
        --http://forums.adafruit.com/viewtopic.php?f=22&t=58064
        Altitude = 44330.0 * (1.0 - ((pressure / SEALEVELPRESSURE_HPA ) ^ 0.1903))
        --print("Approx. Altitude = " .. string.format("%4.1f",Altitude) .." m")
    end
end

read_pm25 = function ()
    sds011 = sensor.attach("SDS011", uart.UART1)
    while true do
        tmr.delay(5)
        
        mtx:lock()
        
        pm25 = math.floor(sds011:read("PM2.5") + 0.5)
        
        mtx:unlock()
        
        print("PM2.5 = "..string.format("%4.1f",pm25).." ug/m3")
    end
end

read_cpu_temp = function ()
    while true do
        tmr.delay(5)
        
        mtx:lock()
        
        cpu_temperature = math.floor(cpu.temperature() * 10) / 10
        
        mtx:unlock()
        
        -- Print results
        --print("CPU Temperature = "..string.format("%2.1f",cpu_temperature).. " *C")
    end
end

send_data = function ()
    -- LoRaWAN Initialize
    lora.attach(lora.BAND923, lora.node)

    -- Set join key
    lora.setDevEui("0011223344556677")
    lora.setAppEui("0011223344556677")
    lora.setAppKey("00112233445566778899AABBCCDDEEFF")

    -- Set datarate SF7 BW125, Adaptive data rate = Disable, Retransmissions = 5 
    lora.setDr(5)
    lora.setAdr(false)
    lora.setReTx(5)
    
    -- Join network
    lora.join()
    
    lora.whenReceived(function(port, payload)
        print("Port=", port , "Payload=", payload)
    end)
    
    -- Send confirmed
    local port = 1
    local confirmed = true
    
    while true do
        tmr.delay(10)
        
        mtx:lock()

        CayenneLPP = ''
        s = pack.pack(math.floor(temperature * 10))
        CayenneLPP = CayenneLPP .. '0167' .. string.sub(s, 7, 8) .. string.sub(s, 5, 6)
        s = pack.pack(math.floor(humidity * 2))
        CayenneLPP = CayenneLPP .. '0268' .. string.sub(s, 5, 6)
        s = pack.pack(math.floor(pressure * 10))
        CayenneLPP = CayenneLPP .. '0373' .. string.sub(s, 7, 8) .. string.sub(s, 5, 6)
        s = pack.pack(math.floor(pm25 * 100))
        CayenneLPP = CayenneLPP .. '0B02' .. string.sub(s, 7, 8) .. string.sub(s, 5, 6)
        
        mtx:unlock()
        
        local port = 1
        local confirmed = true

        try(
            function()
            -- Send confirmed message
            print("Send a confermed payload = " .. CayenneLPP .. ", Port = " .. port)
            lora.tx(confirmed, port, CayenneLPP)
        end,
        
        -- catch_function
        function(where, line, error, message)
            if (error == 100663304) then
                print(message)
                print("Reboot in 5 mins ...")
                tmr.delayms(10)
                os.sleep(300)
            end
        end
        )  
        print("Send completed")
    end
end

show_data = function ()
    -- Setup Graphic Display
    gdisplay.attach(gdisplay.SSD1306_128_64, gdisplay.LANDSCAPE, true, 0x3c)
    dw, dh = gdisplay.getscreensize()
    
    -- Draw "LoRaWAN Thailand"
    gdisplay.clear()
    gdisplay.setfont(gdisplay.FONT_DEJAVU24)
    gdisplay.write({gdisplay.CENTER,10},"LoRaWAN")
    gdisplay.write({gdisplay.CENTER,40},"Thailand")
    tmr.delay(3)
    
    gdisplay.clear();
    gdisplay.setfont(gdisplay.FONT_DEFAULT)
    gdisplay.write({85,0}, "PM2.5")
    gdisplay.setfont(gdisplay.FONT_LCD)
    gdisplay.write({90,16}, "ug/m3")
    
    gdisplay.write({(dw/2)-12, 38}, "C", gdisplay.WHITE, gdisplay.BLACK)
    gdisplay.write({dw -10, 38}, "%", gdisplay.WHITE, gdisplay.BLACK)
    gdisplay.write({dw -20, dh-9}, "hPa", gdisplay.WHITE, gdisplay.BLACK)
    
    gdisplay.line({0,35}, {dw,35}, gdisplay.WHITE)
    gdisplay.line({dw/2-3,36}, {dw/2-3,dh}, gdisplay.WHITE)
    
    local q = 0
    local t = 0
    local h = 0
    local p = 0
    
    local u = 0
    local d = 0
    
    local connected = false
    local ind = 0
    
    while true do
        
        local redraw = 0
        
        mtx:lock()
        
        if (q ~= pm25) then
            q = pm25
            redraw = redraw + 1
        end
        
        if (t ~= temperature) then
            t = temperature
            redraw = redraw + 2
        end
        
        if (h ~= humidity) then
            h = humidity
            redraw = redraw + 4
        end
        
        if (p ~= pressure) then
            p = pressure
            redraw = redraw + 8
        end
        
        if (u ~= lora.getFCntUp()) or (d ~= lora.getFCntDn()) then
            connected = true
            u = lora.getFCntUp()
            d = lora.getFCntDn()
            redraw = redraw + 16
        end
        
        mtx:unlock()
        
        if (redraw >= 16) then
            gdisplay.setfont(gdisplay.FONT_LCD)
            gdisplay.rect ({0, 35 - gdisplay.getfontheight()}, dw/2 - 5, gdisplay.getfontheight(), gdisplay.BLACK, gdisplay.BLACK)
            gdisplay.write({0, 35 - gdisplay.getfontheight()}, '^' .. tostring(u-1))
            redraw = redraw - 16
            ind = 0
        end
        
        if (redraw >= 8) then
            gdisplay.setfont(gdisplay.FONT_LCD)
            gdisplay.rect ({dw/2 + 2, dh-gdisplay.getfontheight()}, dw/2 - 2 - 20, gdisplay.getfontheight(), gdisplay.BLACK, gdisplay.BLACK)
            gdisplay.write({dw/2 + 2, dh-gdisplay.getfontheight()}, tostring(p), gdisplay.WHITE, gdisplay.BLACK)
            redraw = redraw - 8
        end
        
        if (redraw >= 4) then
            gdisplay.setfont(gdisplay.FONT_DEFAULT)
            gdisplay.rect ({dw/2 + 10, 38}, (dw/2) - 10 - 20, gdisplay.getfontheight(), gdisplay.BLACK, gdisplay.BLACK)
            gdisplay.write({dw/2 + 10, 38}, tostring(h), gdisplay.WHITE, gdisplay.BLACK)
            redraw = redraw - 4
        end
        
        if (redraw >= 2) then
            gdisplay.setfont(gdisplay.FONT_DEJAVU18)
            gdisplay.rect ({0,43}, (dw/2) - 15, gdisplay.getfontheight(), gdisplay.BLACK, gdisplay.BLACK)
            gdisplay.write({2,43}, tostring(t), gdisplay.WHITE, gdisplay.BLACK)
            redraw = redraw - 2
        end
        
        if (redraw >= 1) then
            gdisplay.setfont(gdisplay.FONT_7SEG)
            gdisplay.rect ({20,2}, dw - 20 - 50, gdisplay.getfontheight(), gdisplay.BLACK, gdisplay.BLACK)
            gdisplay.write({20,2}, string.format("%03d",q), gdisplay.WHITE, gdisplay.BLACK)
            redraw = redraw - 1
        end
        
        ind = ind + 1
        if (ind == 1) then
            gdisplay.putpixel({5,15})
        end
        
        if (ind == 2) then
            gdisplay.circle({5,15}, 2)
        end
        
        if (ind == 3) then
            gdisplay.circle({5,15}, 5)
        end
        
        if (ind == 4) then
            gdisplay.rect({0,10}, 11, 11, gdisplay.BLACK, gdisplay.BLACK)
        end
        
        if (ind >= 4) then
            if not connected then
                ind = 0
                tmr.delayms(1400)
            end
        else
            tmr.delayms(200)
        end
    end
end

-- Show logging debug
--os.loglevel(os.LOG_DEBUG)

thread.start(read_pm25)
thread.start(read_environ)
--thread.start(read_cpu_temp)
thread.start(show_data)
thread.start(send_data)