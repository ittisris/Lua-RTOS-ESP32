-- bme280_otaa.lua
local mtx = thread.createmutex()

local temperature = 0.0
local humidity = 0
local pressure = 0

local counter = 0
local rxPayload = ""

-- Read data
thread.start(function ()
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
        --print("Temperature = " .. string.format("%3.1f",temperature) .. " *C")
        --print("Humidity = " .. string.format("%2.1f",humidity) .." %")
        --print("Pressure = ".. string.format("%4.1f",pressure) .." hPa")
    end
end
)

-- Show data
thread.start(function()
    local line
    local line_spacing

    -- Setup Graphic Display
    gdisplay.attach(gdisplay.SSD1306_128_64, gdisplay.LANDSCAPE, true, 0x3c)
    dw, dh = gdisplay.getscreensize()
    
    -- Draw "LoRaWAN Thailand"
    gdisplay.clear()
    gdisplay.setfont(gdisplay.FONT_DEJAVU24)
    gdisplay.write({gdisplay.CENTER,10},"LoRaWAN")
    gdisplay.write({gdisplay.CENTER,40},"Thailand")
    tmr.delay(3)

    --gdisplay.setfont(gdisplay.DEJAVU_16)
    gdisplay.setfont("/@font/Sinclair_S.fon")
    line_spacing = gdisplay.getfontheight() + 4

    while true do
        tmr.delay(5)

        mtx:lock()

        gdisplay.clear()

        line = 0
        x = 0
        gdisplay.write(x,line * line_spacing,"T: "..string.format("%4.1f",temperature).." C")
      
        line = line + 1
        gdisplay.write(x,line * line_spacing,"H: "..string.format("%4.1f",humidity).." %")
          
        line = line + 1
        gdisplay.write(x,line * line_spacing,"P: "..string.format("%4.1f",pressure).." hPa")
        
        line = line + 1
        gdisplay.write(x,line * line_spacing,"C: "..counter)
        
        line = line + 1
        gdisplay.write(x,line * line_spacing,"R: "..rxPayload)
        rxPayload = ''
        
        mtx:unlock()
    end
end
)

-- Send data
thread.start(function()
        -- LoRaWAN Initialize
    lora.attach(lora.BAND923, lora.node)

    -- Set LoRaWAN key for lua-rtos-esp32/ttgo002
    lora.setDevEui("0011223344556677")
    lora.setAppEui("0011223344556677")
    lora.setAppKey("00112233445566778899AABBCCDDEEFF")

    -- Set Datarate DR5 (SF7BW125), Adaptive data rate = Disable, Retransmissions = 5 
    lora.setDr(5)
    lora.setAdr(true)
    lora.setReTx(5)

    lora.join()

    lora.whenReceived(function(port, Payload)
        print("Receive Payload = " .. Payload .. " Port = " .. port)
        rxPayload = Payload
    end)

    while true do

        mtx:lock()

        -- Convert to Cayenne Low Power Payload
        local CayenneLPP = ''
        s =  pack.pack(math.floor(temperature * 10))
        CayenneLPP = CayenneLPP..'0167' .. string.sub(s, 7, 8) .. string.sub(s, 5, 6)
        s =  pack.pack(math.floor((humidity *2) + 0.5))
        CayenneLPP = CayenneLPP..'0268' .. string.sub(s, 5, 6)
        s =  pack.pack(math.floor(pressure * 10))
        CayenneLPP = CayenneLPP..'0373' .. string.sub(s, 7, 8) .. string.sub(s, 5, 6)
    
        mtx:unlock()

        -- Send confirmed
        local port = 1
        local confirmed = true

        --print("Send a confermed payload = " .. CayenneLPP .. ", Port = " .. port)
        
        try(
            function()
                lora.tx(confirmed, port, CayenneLPP)
                counter = lora.getMsgID()
                --print("Frames up = " .. counter)
            end,
            
            -- catch_function
            function(where, line, error, message)
                --print(message)
            end
        )
    
        tmr.delay(20)
    end
end
)
