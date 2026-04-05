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
  - Those peripherals have services 
    - Services have charecteristics
      - Charecteristics can be read and written to
      - Characteristics have descriptors
        - Descriptors can be read and written to

# Usage example
```julia

const SERVICE_UUID					= "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
const CHARACTERISTIC_UUID_TX		= "beb5483e-36e1-4688-b7f5-ea07361b26a8"
const CHARACTERISTIC_UUID_RX		= "6d68ef76-79f6-4b8a-bf9d-05fc906b8290"
const CHARACTERISTIC_UUID_CONFIG	= "3c3d5e6f-7a8b-4c9d-9e0f-1a2b3c4d5e6f"

using SimpleBLE
using JSON

adapter = get_adapter(0)
peri = find_peripheral(adapter) do id
	occursin("SiNW", id)
end
connect(peri) do
	# You generally need to know the UUIDs of things in advance
	# since they don't have names, but you can query a peripheral
	# about its properties with `peripheral_services_get`
	SERVICE_UUID				= "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
	CHARACTERISTIC_UUID_TX		= "beb5483e-36e1-4688-b7f5-ea07361b26a8"
	CHARACTERISTIC_UUID_RX		= "6d68ef76-79f6-4b8a-bf9d-05fc906b8290"
	CHARACTERISTIC_UUID_CONFIG	= "3c3d5e6f-7a8b-4c9d-9e0f-1a2b3c4d5e6f"


	@info "Writing Commands"
	write_request(peri, SERVICE_UUID, CHARACTERISTIC_UUID_RX, JSON.json("cmd" => "start"))
	write_request(peri, SERVICE_UUID, CHARACTERISTIC_UUID_RX, JSON.json(Dict("cmd"=>"set_rate", "rate"=>samplerate)))

	sleep(0.5)

	@info "Setting up data stream"
	currtime = replace(string(now()), ':'=>"", '-'=>"")
	f = open("logs_$currtime.csv", "w")
	writedlm(f, ["Time [ms]" "Currrent"], ',')
	counter = 0
	notify(peri, SERVICE_UUID, CHARACTERISTIC_UUID_TX) do data
		counter += 1
		jdata = JSON.parse(String(data))
		writedlm(f, Any[jdata["timestamp"] jdata["current"]], ',')
	end
	@info "Press enter to end stream"
	dispnum = true
	errormonitor(@async while dispnum
		print("\b"^100*"Total samples collected: $counter")
		sleep(1)
	end)
	readline()
	dispnum = false
	close(f)
end
```
