-- Public to MQTT topic '/lua-rtos-esp32'
m_lock = thread.createmutex()

-- every 10 seconds
thread.start(function()
	while (true) do
		if (not(net.connected())) then
			print("Wait network connected ...")
		else
			try(
				function()
					-- create the MQTT client and connect, if needed
					m_lock:lock()
					if (client == nil) then
						client = mqtt.client("mqtt", "iot.eclipse.org", 1883, false, nil, true)
						client:connect("","")
					end
					m_lock:unlock()
					
					-- Publish to topic
					client:publish('/lua-rtos-esp32', 'Hello world', mqtt.QOS0)
				end,
				function(where, line, err, message)
					print(err, message)
				end
			)			
		end
		tmr.delayms(10000)
	end
end)