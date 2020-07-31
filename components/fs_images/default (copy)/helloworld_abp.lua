-- helloworld_abp.lua
os.loglevel(os.LOG_DEBUG)
thread.start(function()
	-- LoRaWAN Initialize
	lora.attach(lora.BAND923, lora.node)

	-- Set LoRaWAN Session Key
    lora.setDevAddr("00112233")
    lora.setNwksKey("00112233445566778899AABBCCDDEEFF")
    lora.setAppsKey("00112233445566778899AABBCCDDEEFF")

	-- Set datarate DR5 SF7BW125, Adaptive data rate = Disable
	lora.setDr(5)
	lora.setAdr(false)
	lora.setReTx(0)

	local port = 1
	local confirmed = false

	while true do
		lora.tx(confirmed, port, string.sub(pack.pack('Hello, world!'), 5))
		tmr.delay(30)
	end
end)