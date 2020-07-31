-- Public to MQTT topic '/lua-rtos-esp32'
_mqtt_lock = thread.createmutex()
-- attach timer every 10 seconds
thread.start(function()
	while (true) do
		if (not(net.connected())) then
			print("Wait network connected ...")
		else
			try(
				function()
					-- create the MQTT client and connect, if needed
					_mqtt_lock:lock()
					if (_mqtt == nil) then
						_mqtt = mqtt.client("mqtt", "iot.eclipse.org", 1883, false, nil, true)
						_mqtt:connect("","")
					end
					_mqtt_lock:unlock()
					
					-- Publish to topic
					_mqtt:publish('/lua-rtos-esp32', 'Hello world', mqtt.QOS0)
				end,
				function(where, line, err, message)
					print(err, message)
				end
			)			
		end
		tmr.delayms(10000)
	end
end)