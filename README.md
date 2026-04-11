[![][docs-stable-img]][docs-stable-url]

# SimpleBLE.jl
A Julia wrapper for interfacing with the [SimpleBLE](https://github.com/simpleble/simpleble.git) bluetooth C library, currently only works on Windows and Linux. If you have an Apple device and are willing to do some testing please open an issue.

## Installation
Currently SimpleBLE.jl is not registered so you'll need to first install the binary wrapper [SimpleBLE_jll](https://github.com/AwesomeQuest/SimpleBLE_jll.git) and then this library

Enter Pkg mode in Julia by typing ] in the REPL
```juliarepl
 pkg> add https://github.com/AwesomeQuest/SimpleBLE_jll.git
 pkg> add https://github.com/AwesomeQuest/SimpleBLE.jl.git
```

# SimpleBLE basics
Bluetooth is a hierarchy
- Bluetooth devices are called peripherals
  - Those peripherals have services 
    - Services have characteristics
      - Characteristics can be read and written to
      - Characteristics can also be either notified or indicated (assigned callbacks that receive data whenever it is sent)
      - Characteristics have descriptors
        - Descriptors can be read and written to

# Usage example
The bellow example is actual code that I used for a project.
```julia
# You generally need to know the UUIDs of things in advance
# since they don't have names, but you can query a peripheral
# about its properties with `services`
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



[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-stable-url]: https://awesomequest.github.io/SimpleBLE.jl/index.html
