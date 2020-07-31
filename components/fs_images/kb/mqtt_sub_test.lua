-- this lock is for protect the mqtt client connection
m_lock = thread.createmutex()

-- Subscribe to MQTT topic '/lua-rtos-esp32'
thread.start(function()
	while (not(net.connected())) do
		tmr.delayms(10000)
		print("Wait network connected ...")
	end
	try(
		function()
			-- create the MQTT client and connect, if needed
			m_lock:lock()
			if (client == nil) then
				client = mqtt.client("mqtt", "iot.eclipse.org", 1883, false, nil, true)
				client:connect("","")
			end
			m_lock:unlock()

			-- Subscribe to topic
			client:subscribe('/lua-rtos-esp32', mqtt.QOS2, function(length, payload)
				print(payload)
			end)
		end,
		
		function(where, line, err, message)
			print(err, message)
		end
	)
end)