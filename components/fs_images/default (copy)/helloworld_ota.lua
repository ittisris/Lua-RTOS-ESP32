-- helloworld_otaa.lua
--os.loglevel(os.LOG_DEBUG)
thread.start(function()
	-- LoRaWAN Initialize
	lora.attach(lora.BAND923, lora.node)

	-- Set LoRaWAN Key
	lora.setDevEui("0011223344556677")
	lora.setAppEui("0011223344556677")
	lora.setAppKey("00112233445566778899AABBCCDDEEFF")

	-- Set Datarate DR5 (SF7BW125), Adaptive data rate = Enable, Retransmissions = 5 
	lora.setDr(5)
	lora.setAdr(true)
	lora.setReTx(5)

	lora.join()

	lora.whenReceived(function(port, payload)
		print("Port=", port , "Payload=", payload)
	end)

	local port = 1
	local confirmed = true

	while true do
		try(
			function()
				lora.tx(confirmed, port, string.sub(pack.pack('Hello, world!'), 5))
			end,
			
			-- catch_function
			function(where, line, error, message)
				print(message)
			end
		)

		tmr.delay(30)
	end
end)