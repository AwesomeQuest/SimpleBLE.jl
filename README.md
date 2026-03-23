# SimpleBLE.jl
A Julia wrapper for interfacing with the [SimpleBLE](https://github.com/simpleble/simpleble.git) bluetooth C library.

Currently I just include a precompiled dll inside the shared directory because I can't figure out how to compile SimpleBLE with BinaryBuilder.jl. 
Only for windows a.t.m. but if anyone want's to test it with a linux .so send an issue and I'll add it (assuming we don't figure out BinaryBuilder.jl).

## Installation
Enter Pkg mode by typing ] in the REPL
```juliarepl
 pkg> add https://github.com/AwesomeQuest/SimpleBLE.jl.git
```

# SimpleBLE basics
Bluetooth is a hierarchy
- Bluetooth devices are called peripherals
  - Those peripherals have services that they provide
    - Services have charecteristics
      - Can be read and written to
      - Characteristics have descriptors
        - Can be read and written to

# Basic Usage example
```julia
# You generally need to know the UUIDs of things in advance
# since they don't have names, but you can query a peripheral
# about its properties with `peripheral_services_get`
const SERVICE_UUID					= "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
const CHARACTERISTIC_UUID_TX		= "beb5483e-36e1-4688-b7f5-ea07361b26a8"
const CHARACTERISTIC_UUID_RX		= "6d68ef76-79f6-4b8a-bf9d-05fc906b8290"
const CHARACTERISTIC_UUID_CONFIG	= "3c3d5e6f-7a8b-4c9d-9e0f-1a2b3c4d5e6f"

using SimpleBLE
using JSON

# This function does things that I like, maybe you don't like them, change them
connect_peripheral(peri->begin
	periid = peripheral_identifier(peri)
	return occursin("recognizable part of name of peripheral", periid)
end) do peri
	rxchar = Characteristic(SERVICE_UUID, CHARACTERISTIC_UUID_RX)
	txchar = Characteristic(SERVICE_UUID, CHARACTERISTIC_UUID_TX)
	confchar = Characteristic(SERVICE_UUID, CHARACTERISTIC_UUID_CONFIG)

	write(peri, rxchar, JSON.json(Dict("cmd"=>"start")))
	write(peri, rxchar, JSON.json(Dict("cmd"=>"set_rate", "rate"=>0)))
	sleep(1)
	responce = read(peri, txchar) |> JSON.parse
	println(JSON.json(responce))
	write(peri, rxchar, JSON.json("cmd"=>"get_config"))
	responce = read(peri, txchar) |> JSON.parse
	println(JSON.json(responce))
end
```
