mtx = thread.createmutex()

--[[
net.wf.setup(net.wf.mode.STA, "ssid", "password")
net.wf.start(true)
--]]

-- bme280
BME280={temperature=0.0}
LM73={temperature=0.0}
diff=0.0

cpu_temperature = 0.0
SEALEVELPRESSURE_HPA = 1013.25

BME280_SLEEP_MODE = 0
BME280_FORCED_MODE = 1
BME280_NORMAL_MODE = 3

thread.start(function ()
    bme280 = sensor.attach("BME280", i2c.I2C0, 0x76)
    lm73 = sensor.attach("LM73", i2c.I2C1, 0)
    
    while true do
        mtx:lock()
        -- Read temperature
        BME280.temperature = math.floor(bme280:read("temperature") * 10) / 10

        -- Read humidity
        BME280.humidity =  math.floor(bme280:read("humidity") * 10) / 10

        -- Read preassure
        BME280.pressure = math.floor(bme280:read("pressure") * 10) / 10
        --print("BME280-Temperature = " .. string.format("%3.1f",BME280.temperature) .. " *C")
        
        LM73.temperature=math.floor(lm73:read("temperature") * 10) / 10
        --print("LM73-Temperature = " .. string.format("%3.1f",LM73.temperature) .. " *C")
        
        mtx:unlock()
        tmr.delay(2)
    end
end,4096,20,1,"read")

gdisplay.attach(gdisplay.HT16K33_16_8)
gdisplay.setfont(gdisplay.FONT_LCD)
gdisplay.on()

thread.start(function()
    while(true) do
        mtx:lock()
        local diff=LM73.temperature-BME280.temperature
        mtx:unlock()
        gdisplay.clear()  
        gdisplay.write({0,gdisplay.CENTER},string.format("    %3.1f",diff))
        tmr.delay(2)
    end
end,4096,20,1,"Display")

thread.start(function()
    local client = nil
    local t1, t2
    
    while (true) do
        tmr.delay(5)
        
        if (not(net.connected())) then
            print("Wait network connected ...")
        else
            mtx:lock()
            t1 = BME280.temperature
            t2 = LM73.temperature
            mtx:unlock()
                    
            try(
                function()
                    if (client == nil) then
                        client = mqtt.client("db577bd0-58fb-11e9-9f74-8b741b61f48a", "mqtt.mydevices.com", 1883, false, nil, false)
                        client:connect("31059eb0-eb37-11e7-a2f9-8f754ce96236","cb580d81544e940eb09c2af61def065fe42d30ba")
                    end
                    client:publish('v1/31059eb0-eb37-11e7-a2f9-8f754ce96236/things/db577bd0-58fb-11e9-9f74-8b741b61f48a/data/1', 'temp,c=' .. t1, mqtt.QOS0)
                    client:publish('v1/31059eb0-eb37-11e7-a2f9-8f754ce96236/things/db577bd0-58fb-11e9-9f74-8b741b61f48a/data/2', 'temp,c=' .. t2, mqtt.QOS0)
                end,
                function(where, line, err, message)
                    print(err, message)
                end
            )
            print("Temperature LM73 =" .. string.format("%3.1f",LM73.temperature) .. ", BME280 =".. string.format("%3.1f",BME280.temperature) .." *C")
        end
    end
end,10000,20,1,"log")

