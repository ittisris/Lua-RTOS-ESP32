-- ldr_demo.lua
-- Setup LDR attached to ADC1 on Chan0 = GPIO36
-- Itti Srisumalai 2019

ldr = adc.attach(adc.ADC1, adc.ADC_CH0)
while(true) do
    tmr.delayms(100)
    raw, millivolts = ldr:read()
    print("Raw ="..raw..",  Voltage (mV) = "..millivolts)
end