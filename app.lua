wifi.sta.sethostname("uopNodeMCU")
wifi.setmode(wifi.STATION)
station_cfg={}
station_cfg.ssid="***" 
station_cfg.pwd="***"
station_cfg.save=true
wifi.sta.config(station_cfg)
wifi.sta.connect()

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
end 

dhtPin=8
greenpinLED=4
orangepinLED=0
redpinLED=7
gpio.mode(greenpinLED,gpio.OUTPUT)
gpio.write(greenpinLED,gpio.LOW)
gpio.mode(orangepinLED,gpio.OUTPUT)
gpio.write(orangepinLED,gpio.LOW)
gpio.mode(redpinLED,gpio.OUTPUT)
gpio.write(redpinLED,gpio.LOW)

HOST="io.adafruit.com"
PORT=1883
PUBLISH_TOPIC="charliebarratt2/feeds/temp"
SUBSCRIBE_TOPIC="charliebarratt2/feeds/temp"
ADAFRUIT_IO_USERNAME="***"
ADAFRUIT_IO_KEY="***"
m=mqtt.Client("Client3",300,ADAFRUIT_IO_USERNAME,ADAFRUIT_IO_KEY)
m:lwt("/lwt","Now offline",1,0)

m:on("connect",function(client) 
print("Client connected") 
print("MQTT client connected to "..HOST)
    mytimer = tmr.create()
    mytimer:register(5000, 1, function()
    status, temp, temp_dec = dht.read11(dhtPin)  
    if status == dht.OK then
    pubTemp(client)
       if temp <= 25 then
         print("Perfect! Temperature low, currently "..temp.."°C")
         gpio.write(greenpinLED,gpio.HIGH)
         gpio.write(orangepinLED,gpio.LOW)
         gpio.write(redpinLED,gpio.LOW)
       elseif (temp > 25 and temp <= 40) then
         print("Temperature OK, currently "..temp.."°C")
         gpio.write(greenpinLED,gpio.LOW)
         gpio.write(orangepinLED,gpio.HIGH)
         gpio.write(redpinLED,gpio.LOW)
       elseif (temp > 40 and temp <= 50) then
         print("Warning, temperature is "..temp.."°C. Action should be taken to avoid further rises in temperature") 
         gpio.write(greenpinLED,gpio.LOW)
         gpio.write(orangepinLED,gpio.LOW)
         gpio.write(redpinLED,gpio.HIGH)
       elseif temp > 50 then
         print("TEMPERATURE TOO HIGH! Current temperature is "..temp.."°C. Action must be taken to avoid damage to parts")
         state = 1
         mytimer = tmr.create()
         mytimer:register(1000, 1, function()
             if state == 1 then
                 gpio.write(greenpinLED,gpio.LOW)
                 gpio.write(orangepinLED,gpio.LOW)
                 gpio.write(redpinLED,gpio.HIGH)
                 state = 0
             else
                 gpio.write(greenpinLED,gpio.LOW)
                 gpio.write(orangepinLED,gpio.LOW)
                 gpio.write(redpinLED,gpio.LOW)
                 state = 1
             end
         end)
         mytimer:start()
       end
    elseif status == dht.ERROR_CHECKSUM then
       print( "DHT Checksum error." )
    elseif status == dht.ERROR_TIMEOUT then
       print( "DHT timed out." )
    end
    end)
    mytimer:start()
end) 

m:on("offline",function(client)
    print("Client offline")
end)

m:connect(HOST,PORT,false,false,function(conn) end,function(conn,reason)
    print("Fail! Failed reason is: "..reason)
end)

function pubTemp(client)
    client:publish(PUBLISH_TOPIC,temp,1,0,function(client)end)
    print("Temp reading sent to dashboard")
end