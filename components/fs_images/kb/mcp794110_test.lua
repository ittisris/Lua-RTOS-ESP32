i = i2c.attach(i2c.I2C1, i2c.MASTER, 100000)

i:start()
i:address(0x6f, false)
i:write(0x20,0x55,0xaa,0x55,0xaa)
i:stop()

--
i:start()
i:address(0x6f, false)
i:write(0x20)

i:start()
i:address(0x6f, true)
x=i:read()
print(x)
x=i:read()
print(x)
x=i:read()
print(x)
x=i:read()
print(x)
i:stop()