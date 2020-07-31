-- this lock is for protect the mqtt client connection
_mqtt_lock = thread.createmutex()

-- Subscribe to MQTT topic '/lua-rtos-esp32'
thread.start(function()
	while (not(net.connected())) do
		tmr.delayms(10000)
		print("Wait network connected ...")
	end
	try(
		function()
			-- create the MQTT client and connect, if needed
			_mqtt_lock:lock()
			if (_mqtt == nil) then
				_mqtt = mqtt.client("mqtt", "iot.eclipse.org", 1883, false, nil, true)
				_mqtt:connect("","")
			end
			_mqtt_lock:unlock()

			-- Subscribe to topic
			_mqtt:subscribe('/lua-rtos-esp32', mqtt.QOS2, function(length, payload)
				print(payload)
			end)
		end,
		
		function(where, line, err, message)
			print(err, message)
		end
	)
end)