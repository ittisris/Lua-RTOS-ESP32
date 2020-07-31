--radmon.lua
--net.wf.setup(net.wf.mode.STA, "ssid", "pass")
--net.wf.start(true)

net.curl.progress(1)
net.curl.verbose(1)
net.curl.timeout(60)

local cnt=0
local cpm=0
local cpmtodose = 0.006

local c_mtx = thread.createmutex()
local cpm_mtx = thread.createmutex()

local user="kidbright32"
local password="kidbright32"
local radmon="http://radmon.org/radmon.php?function=submit&user=".. user .."&password=".. password .."&value=nCPM&unit=CPM"

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

-- click-sound
pio.pin.setdir(pio.OUTPUT, pio.SPRK)
pio.pin.setpull(pio.NOPULL, pio.SPRK)

-- pulse input changed to pio.IN1 on real board.        
pio.pin.interrupt(pio.SW1, function()
        pio.pin.setval(1, pio.SPRK)
        pio.pin.setval(0, pio.IOT_LED)
        c_mtx:lock()
        cnt = cnt + 1
        c_mtx:unlock()
        pio.pin.setval(1, pio.IOT_LED)
        pio.pin.setval(0, pio.SPRK)
end, pio.pin.IntrPosEdge)

-- Compute CPM
thread.start(function()
    local counter_a = {}
    local c0 = 0
    local cps=0

    while (true) do
        tmr.delayms(1000)
        
        c_mtx:lock()
        cps = cnt - c0
        c0 = cnt
        c_mtx:unlock()
        
        cpm_mtx:lock()
        cpm = math.floor(60 * average(counter_a, cps, 60))
        cpm_mtx:unlock()
    end
end,2048,22,1,'cpm')

-- display loop
thread.start(function()
    local cpm0 = 0
    local cpm1 = 0

    gdisplay.attach(gdisplay.HT16K33_16_8)
    local xsize, ysize = gdisplay.getscreensize()
    gdisplay.setfont(gdisplay.FONT_LCD)
    gdisplay.setwrap(false)
    gdisplay.setfixed(true)
    gdisplay.clear()
    --gdisplay.write({gdisplay.RIGHT,0}, "rad")
    gdisplay.on()

    while(true) do

        cpm_mtx:lock()
        cpm1 = cpm
        cpm_mtx:unlock()

        if( cpm1 ~= cpm0) then
            print(cpm1)
            --gdisplay.clear()
            gdisplay.write({gdisplay.RIGHT,0}, string.format("%d",cpm0),gdisplay.BLACK)
            gdisplay.write({gdisplay.RIGHT,0}, string.format("%d",cpm1))
            cpm0 = cpm1
        end

        tmr.delayms(1000)
    end
end,4096,22,1,'display')

-- sendto radmon.org
thread.start(function()
    local url = ""   
    local ncpm = 0
    --local a_cpm = {}
    
    while (true) do
        if(not(net.connected())) then
            while (not(net.connected())) do
                print("Wait network connected ...")
                tmr.delay(10)
            end
            net.stat()
        end
        
        tmr.delay(60)
        
        cpm_mtx:lock()
        ncpm = cpm
        cpm_mtx:unlock()
        
        url = string.gsub(radmon,"nCPM",string.format("%d",ncpm))
        --math.floor(ncpm), average(a_cpm, ncpm, 30)
        print(url)

        res, hdr, bdy = net.curl.get(url)
        print('res', res)
    end
end,8704,22,1,'radmon')
