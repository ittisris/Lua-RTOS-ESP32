--radmon.lua
--Itti Srisumalai 2019

os.loglevel(os.LOG_DEBUG)

--[[
net.wf.setup(net.wf.mode.STA, "ssid", "pass")
net.wf.start(true)
--]]

net.curl.progress(1)
net.curl.verbose(1)
net.curl.timeout(60)


local cnt=0
local cpm=0
local cpmtodose = 0.006
local cpmmode=true
local mon=true

local c_mtx = thread.createmutex()
local d_mtx = thread.createmutex()

local user="ittisris"
local password="radmon"
local radmon="http://radmon.org/radmon.php?function=submit&user=".. user .."&password=".. password .."&value=nCPM&unit=CPM"

--
gdisplay.attach(gdisplay.HT16K33_16_8)
gdisplay.setfont(gdisplay.FONT_LCD)
gdisplay.setwrap(false)
gdisplay.clear()
gdisplay.write({15,0},"radmon")
gdisplay.setwrap(true)
--

--
local function average(ar, v, n)
    local avg = 0
    local s = 0
    local i
    
    s = #ar or 0
    if(s < n) then
        s = s + 1
    else
        table.remove (ar, 1)
        s = n
    end
    
    ar[s] = v
    for i=1, s, 1 do
        avg = avg + ar[i]
    end
    return (avg/s)
end
--

--
-- Button SW2 to select mode
local sw2 = sensor.attach("PUSH_SWITCH", pio.SW2)
sw2:callback(function(data)
    if (data.on == 0) then
        cpmmode=not cpmmode
        gdisplay.clear()
        d_mtx:lock()
        mon=true
        gdisplay.setwrap(false)
        if(cpmmode) then
            gdisplay.write({15,0}, "cpm")
        else
            gdisplay.write({15,0}, "uSv/h")
        end
        gdisplay.setwrap(true)
        d_mtx:unlock()
    end
end)
--

--
-- Button SW1 to turn display on/off
local sw2 = sensor.attach("PUSH_SWITCH", pio.SW1)
sw2:callback(function(data)
    if (data.on == 0) then
        d_mtx:lock()
        mon=not mon
        if(mon==false)then
            gdisplay.clear()
            gdisplay.setwrap(false)
            gdisplay.write({15,0}, "Dispaly off")
            gdisplay.setwrap(true)
            gdisplay.clear()
        end
        d_mtx:unlock()
    end
end)
--

--
-- click-sound
pio.pin.setdir(pio.OUTPUT, pio.SPRK)
pio.pin.setpull(pio.NOPULL, pio.SPRK)
pio.pin.setdir(pio.OUTPUT, pio.IOT_LED)

-- pulse input changed to pio.IN1 on real board.
pio.pin.interrupt(pio.IN1, function()
    pio.pin.setval(0, pio.IOT_LED)
    if(mon)then
        pio.pin.setval(1, pio.SPRK)
        c_mtx:lock()
        cnt = cnt + 1
        c_mtx:unlock()
        pio.pin.setval(0, pio.SPRK)
    else
        c_mtx:lock()
        cnt = cnt + 1
        c_mtx:unlock()
    end
    pio.pin.setval(1, pio.IOT_LED)
end, pio.pin.IntrPosEdge)
--

--
local counter_a = {}
t0 = tmr.attach(tmr.TMR1, 1000000, function()
    c_mtx:lock()
    cps = cnt
    cnt = 0
    c_mtx:unlock()
    cpm = math.floor(60 * average(counter_a, cps, 60))
    --print(cpm)
end)
t0:start()

--
-- display loop
thread.start(function()
    local cpm1 = 0
    while(true) do
        --cpm_mtx:lock()
        --cpm1 = cpm
        --cpm_mtx:unlock()

        if( cpm1 ~= cpm) then
            cpm1 = cpm
            --print(cpm1)
            d_mtx:lock()
            if(mon==true) then
                gdisplay.clear()
                if(cpmmode) then
                    gdisplay.write({gdisplay.RIGHT,0}, string.format("%d",cpm1))
                else
                    gdisplay.write({gdisplay.RIGHT,0}, string.format("%2.1f",cpm1*cpmtodose))
                end
            end
            d_mtx:unlock()
        end

        tmr.delayms(500)
    end
end,4096,20,0,'display')
--

--
-- sendto radmon.org
local url = ""   
local ncpm = 0

while (true) do
    net.stat()
    if (not(net.connected())) then
        print("Wait network connected ...")
        tmr.delay(5)
    else
        tmr.delay(60)
        
        --cpm_mtx:lock()
        ncpm = cpm
        --cpm_mtx:unlock()
        
        url = string.gsub(radmon,"nCPM",string.format("%d",ncpm))
        --math.floor(ncpm), average(a_cpm, ncpm, 30)
        print(url)
    
        res, hdr, bdy = net.curl.get(url)
        print('res', res)
    end
end