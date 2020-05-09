wifi.sta.sethostname("uopNodeMCU")
wifi.setmode(wifi.STATION)
station_cfg={}
station_cfg.ssid="TheBarratts" 
station_cfg.pwd="889F0A7C1D"
station_cfg.save=true
wifi.sta.config(station_cfg)
wifi.sta.connect()

mytimer = tmr.create()
mytimer:register(5000, 1, function() 
   if wifi.sta.getip()==nil then
        print("Connecting to AP...\n")
   else
        ip, nm, gw=wifi.sta.getip()
        mac = wifi.sta.getmac()
        rssi = wifi.sta.getrssi()
        print("IP Info: \nIP Address: ",ip)
        print("Netmask: ",nm)
        print("Gateway Addr: ",gw)
        print("MAC: ",mac)  
        print("RSSI: ",rssi,"\n")
        mytimer:stop()
   end 
end)
mytimer:start()

dhtPin = 8
greenpinLED=4
orangepinLED=0
redpinLED=2
state = 1
gpio.mode(greenpinLED,gpio.OUTPUT)
gpio.write(greenpinLED,gpio.LOW)
gpio.mode(orangepinLED,gpio.OUTPUT)
gpio.write(orangepinLED,gpio.LOW)
gpio.mode(redpinLED,gpio.OUTPUT)
gpio.write(redpinLED,gpio.LOW)

HOST="io.adafruit.com"--adafruit host
PORT=1883--1883 or 8883(1883 for default TCP, 8883 for encrypted SSL or other ways)
PUBLISH_TOPIC='charliebarratt/feeds/LED1' -- put your topic of publish shown on the IoT platform/broker site
SUBSCRIBE_TOPIC="charliebarratt/feeds/LED1" -- put your topic of subscribe shown on the IoT platform/broker site
ADAFRUIT_IO_USERNAME="charliebarratt"--put your own username here
ADAFRUIT_IO_KEY="aio_mkOR24stbhDvP2LswNfa2BZEI97n"--put your own io_key here
-- init mqtt client with logins, keepalive timer 300 seconds
m=mqtt.Client("Client1",300,ADAFRUIT_IO_USERNAME,ADAFRUIT_IO_KEY)
-- setup Last Will and Testament (optional)
-- Broker will publish a message with qos = 1, retain = 0, data = "offline"
-- to topic "/lwt" if client does not send keepalive packet
m:lwt("/lwt","Now offline",1,0)
--on different event "connect","offline","message",...
m:on("connect",function(client) 
    print("Client connected") 
    print("MQTT client connected to "..HOST)
    client:subscribe(SUBSCRIBE_TOPIC,1,function(client)
        print("Subscribe successfully") 
        end)
end)

m:on("offline",function(client)
    print("Client offline")
end)

status, temp, temp_dec = dht.read11(dhtPin)
if status == dht.OK then
--3 different status
--dht.OK, dht.ERROR_CHECKSUM, dht.ERROR_TIMEOUT
print("DHT Temperature:"..temp)
-- 2 dots are used for concatenation
elseif status == dht.ERROR_CHECKSUM then
print( "DHT Checksum error." )
elseif status == dht.ERROR_TIMEOUT then
print( "DHT timed out." )
end

m:on("message",function(client,topic,data)
print(topic .. ":" ) 
if data ~= nil then
print(data)
mytimer = tmr.create()
mytimer:register(5000, 1, function() 
  print(topic .. ":" ) 
  if data=='OFF' then
    print("MQTT Client turned off")
  else
      if temp <= 30 then
        print("Perfect! Temperature low, currently "..temp)
        gpio.write(greenpinLED,gpio.HIGH)
        gpio.write(orangepinLED,gpio.LOW)
        gpio.write(redpinLED,gpio.LOW)
      elseif (temp > 30 and temp <= 50) then
        print("Great! Temperature OK, currently "..temp)
        gpio.write(greenpinLED,gpio.LOW)
        gpio.write(orangepinLED,gpio.HIGH)
        gpio.write(redpinLED,gpio.LOW)
      elseif (temp > 50 and temp <= 70) then
        print("Warning, temperature is "..temp..". Action should be taken to avoid further rises in temperature")
        gpio.write(greenpinLED,gpio.LOW)
        gpio.write(oramgepinLED,gpio.LOW)
        gpio.write(redpinLED,gpio.HIGH)
      elseif temp > 70 then
        print("Temperature too high! Current temperature is "..temp..". Action must be taken to avoid damage to parts")
        mytimer = tmr.create()
        mytimer:register(1000, 1, function()
        if state == 1 then
            gpio.write(greenpinLED,gpio.LOW)
            gpio.write(oramgepinLED,gpio.LOW)
            gpio.write(redpinLED,gpio.HIGH) --MAKE THIS FLASH ON AND OFF
            state = 1
        else
            gpio.write(greenpinLED,gpio.LOW)
            gpio.write(oramgepinLED,gpio.LOW)
            gpio.write(redpinLED,gpio.LOW)
            state = 0
        end
        end)
        mytimer:start()
      end
end)
end)

--m:on("message",function(client,topic,data)
--  print(topic .. ":" ) 
--  if data ~= nil then
--    print(data)
--    if data=='OFF' then LEDOnOff=0
--    else LEDOnOff=1 
--    end
--    if LEDOnOff==1 or LEDOnOff==0 then   
--        gpio.write(pinLED,LEDOnOff)
--    end
--  end
--end)
--m:on

m:connect(HOST,PORT,false,false,function(conn) end,function(conn,reason)
    print("Fail! Failed reason is: "..reason)
end)
