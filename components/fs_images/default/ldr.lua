-- ldr.lua
-- Setup LDR attached to ADC1 on Chan0 = GPIO36
-- Itti Srisumalai 2019

gdisplay.attach(gdisplay.HT16K33_16_8)
gdisplay.settransp(false)
local xsize, ysize = gdisplay.getscreensize()
gdisplay.on()

local a = {}

local function draw(ar, v, n)
    local s
    local i
    
    s = #ar or 0
    
    if(s == n) then
        -- scroll left
        gdisplay.putpixel({0,   ar[1]},gdisplay.BLACK)
        for i=1, n-1 , 1 do
            gdisplay.putpixel({i-1,ar[i+1]},gdisplay.WHITE)
            gdisplay.putpixel({i,  ar[i+1]},gdisplay.BLACK)
        end
        gdisplay.putpixel({n-1,ar[n]},gdisplay.BLACK)
        table.remove (ar, 1)
    end
    
    if(s < n) then
        s = s + 1
    end
    
    ar[s] = v
    gdisplay.putpixel({s-1,v},gdisplay.WHITE)
end

ldr = adc.attach(adc.ADC1, adc.ADC_CH0)
local y=0
while(true) do
    tmr.delayms(1)
    raw, millivolts = ldr:read()
    --print("Raw ="..raw..",  Voltage (mV) = "..millivolts)
    y=ysize-math.floor(((1024-raw)/128)+0.5)
    draw(a,y,16)
end