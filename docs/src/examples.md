# Examples

The following examples are recreations from [here](https://github.com/simpleble/simpleble/tree/4eb5efcb30f0b531bbb458ecee67e798e496346f/examples/simpleble/src)

## Connect
```julia
adapter = get_adapter(0)
peripherals = Peripheral[]
set_callback_on_scan_found(adapter) do peri
	println("Found device: ", identifier(peri), "[",address(peri),"]")
	if is_connectable(peri)
		push!(peripherals, peri)
	end
end
set_callback_on_scan_start(()->println("Scan started"), adapter)
set_callback_on_scan_stop(()->println("Scan stopped"), adapter)
scan_for(5000)

println("The following connectable devices were found")
for (i,p) in enumerate(peripherals)
	println("[$i] ", identifier(p), " [$(address(p))]")
end

print("Please select a device to connect to")
selection = parse(Int, readline())
selection in eachindex(peripherals) || exit(1)

peri = peripherals[selection]
println("Connecting to ", identifier(peri), " [",address(peri),"]")
connect(peri) do 
	println("Successfully connected.")
	println("MTU: ", mtu(peri))
	for S in services(peri)
		println("Service: ", S.uuid)
		for C in S.characteristics
			println("\tCharacteristic: ", C.uuid)
			print("\t\tCapabilities: ")
			print(" can_read: $(C.can_read)")
			print(" can_write_request: $(C.can_write_request)")
			print(" can_write_command: $(C.can_write_command)")
			print(" can_notify: $(C.can_notify)")
			print(" can_indicate: $(C.can_indicate)")
			println()
			for D in C.descriptors
				println("\t\t\tDescriptor: ", D.uuid)
			end
		end
	end
end
```

## Indicate / notify

```julia
adapter = get_adapter(0)
peripherals = Peripheral[]
set_callback_on_scan_found(adapter) do peri
	println("Found device: ", identifier(peri), "[",address(peri),"]")
	if is_connectable(peri)
		push!(peripherals, peri)
	end
end
set_callback_on_scan_start(()->println("Scan started"), adapter)
set_callback_on_scan_stop(()->println("Scan stopped"), adapter)
scan_for(5000)

println("The following connectable devices were found")
for (i,p) in enumerate(peripherals)
	println("[$i] ", identifier(p), " [$(address(p))]")
end

print("Please select a device to connect to")
selection = parse(Int, readline())
selection in eachindex(peripherals) || exit(1)

peri = peripherals[selection]
println("Connecting to ", identifier(peri), " [",address(peri),"]")
connect(peri) do 
	println("Successfully connected.")

	uuids = Tuple{SBLEUUID, SBLEUUID}[]
	for S in services(peri)
		for C in S.characteristics
			C.can_indicate || continue
			push!(uuids, (S.uuid, C.uuid))
		end
	end

	for (i, (S,C)) in enumerate(uuids)
		println("[$i] $S $C")
	end

	print("Please select a characteristic to indicate")
	selection = parse(Int, readline())
	selection in eachindex(uuids) || error("Incorrect selection")

    # This could also be notify
	indicate(peri, uuids[selection]...) do data
		println("Received: ", data)
	end
	sleep(5)

	unsubscribe(peri, uuids[selection]...)
end
```

## List adapters
```julia
println("Using SimpleBLE version", SimpleBLE.simpleble_get_version())
println("Bluetooth enabled: ", SimpleBLE.is_bluetooth_enabled())

for A in get_adapters()
	println("Adapter: ", identifier(A), " [", address(A),"]")
end
```

## List paired
```julia
println("Using SimpleBLE version", SimpleBLE.simpleble_get_version())
println("Bluetooth enabled: ", SimpleBLE.is_bluetooth_enabled())

for A in get_adapters()
	println("Adapter: ", identifier(A), " [", address(A),"]")
	for P in get_paired_peripherals(A)
		println("\tPeripheral: ", identifier(P), " [", address(P),"]")
	end
end
```

## Multiconnect

```julia

adapter = get_adapter(0)
peripherals = Peripheral[]
set_callback_on_scan_found(adapter) do peri
	println("Found device: ", identifier(peri), "[",address(peri),"]")
	if is_connectable(peri)
		push!(peripherals, peri)
	end
end
set_callback_on_scan_start(()->println("Scan started"), adapter)
set_callback_on_scan_stop(()->println("Scan stopped"), adapter)
scan_for(5000)

println("The following connectable devices were found")
for (i,p) in enumerate(peripherals)
	println("[$i] ", identifier(p), " [$(address(p))]")
end

print("Please select a device to connect to")
selection = parse(Int, readline())
selection in eachindex(peripherals) || exit(1)

peri = peripherals[selection]
println("Connecting to ", identifier(peri), " [",address(peri),"]")

for i in 1:5
	!connect(peri) || error("Failed at $i to connect")
	println("Successfully connected.")
	sleep(2)
	!disconnect(peri) || error("Failed at $i to disconnect")
	println("Successfully disconnected.")
end
```

## Notify multi

```julia

mutable struct AtomicBool
	@atomic val::Bool
end
print_allowed = AtomicBool(false)

adapter = get_adapter(0)
peripherals = Peripheral[]
set_callback_on_scan_found(adapter) do peri
	println("Found device: ", identifier(peri), "[",address(peri),"]")
	if is_connectable(peri)
		push!(peripherals, peri)
	end
end
set_callback_on_scan_start(()->println("Scan started"), adapter)
set_callback_on_scan_stop(()->println("Scan stopped"), adapter)

connected_peris = Peripheral[]

for i in 1:2
	empty!(peripherals)
	scan_for(5000)

	println("The following connectable devices were found")
	for (i,p) in enumerate(peripherals)
		println("[$i] ", identifier(p), " [$(address(p))]")
	end

	print("Please select a device to connect to")
	selection = parse(Int, readline())
	selection in eachindex(peripherals) || exit(1)

	peri = peripherals[selection]
	println("Connecting to ", identifier(peri), " [",address(peri),"]")
	connect(peri) || error("Failed to connect")
	push!(connected_peris, peri)

	uuids = Tuple{SBLEUUID, SBLEUUID}[]
	for S in services(peri)
		for C in S.characteristics
			C.can_indicate || continue
			push!(uuids, (S.uuid, C.uuid))
		end
	end

	for (i, (S,C)) in enumerate(uuids)
		println("[$i] $S $C")
	end

	print("Please select a characteristic to indicate")
	selection = parse(Int, readline())
	selection in eachindex(uuids) || error("Incorrect selection")

	notify(peri, uuids[selection]...) do data
		if @atomic print_allowed.val
			println("Peripheral ", identifier(peri), " received: ", data)
		end
	end
end

@atomic print_allowed.val = true

sleep(5)

disconnect(connected_peris[2])

sleep(3)

disconnect(connected_peris[1])
```

## Power cycle

```julia
println("Using SimpleBLE version", SimpleBLE.simpleble_get_version())
println("Bluetooth enabled: ", SimpleBLE.is_bluetooth_enabled())

for A in get_adapters()
	id = identifier(A)
	adr = address(A)
	println("Adapter: $id [$adr]")
	set_callback_on_power_on(A) do 
		println("Adapter $id powered on")
	end
	set_callback_on_power_off(A) do 
		println("Adapter $id powered off")
	end

	println("Adapter powered: ", is_powered(A))
	power_off(A)
	println("Adapter powered: ", is_powered(A))

	sleep(5)

	println("Adapter powered: ", is_powered(A))
	power_on(A)
	println("Adapter powered: ", is_powered(A))
end
```


## Read

```julia
adapter = get_adapter(0)
peripherals = Peripheral[]
set_callback_on_scan_found(adapter) do peri
	println("Found device: ", identifier(peri), "[",address(peri),"]")
	if is_connectable(peri)
		push!(peripherals, peri)
	end
end
set_callback_on_scan_start(()->println("Scan started"), adapter)
set_callback_on_scan_stop(()->println("Scan stopped"), adapter)
scan_for(5000)

println("The following connectable devices were found")
for (i,p) in enumerate(peripherals)
	println("[$i] ", identifier(p), " [$(address(p))]")
end

print("Please select a device to connect to")
selection = parse(Int, readline())
selection in eachindex(peripherals) || exit(1)

peri = peripherals[selection]
println("Connecting to ", identifier(peri), " [",address(peri),"]")
connect(peri) do 
	println("Successfully connected.")

	uuids = Tuple{SBLEUUID, SBLEUUID}[]
	for S in services(peri)
		for C in S.characteristics
			C.can_indicate || continue
			push!(uuids, (S.uuid, C.uuid))
		end
	end

	for (i, (S,C)) in enumerate(uuids)
		println("[$i] $S $C")
	end

	print("Please select a characteristic to read")
	selection = parse(Int, readline())
	selection in eachindex(uuids) || error("Incorrect selection")

	for i in 1:5
		rx_data = peripheral_read(peri, uuids[selection]...)
		println("Characteristic content is: ", rx_data)
		sleep(1)
	end
end
```

## Scan

```julia

adapter = get_adapter(0)
peripherals = Peripheral[]
set_callback_on_scan_found(adapter) do peri
	println("Found device: ", identifier(peri), "[",address(peri),"]",
	peripheral_rssi(peri), " dBm")
end
set_callback_on_scan_updated(adapter) do peri
	println("Updated device: ", identifier(peri), "[",address(peri),"]",
	peripheral_rssi(peri), " dBm")
end
set_callback_on_scan_start(()->println("Scan started"), adapter)
set_callback_on_scan_stop(()->println("Scan stopped"), adapter)
scan_for(2000)

println("Scan complete.")

println("The following devices were found:")
for P in scan_get_results(adapter)
	connectable_string = is_connectable(P) ? "Connectable" : "Non-Connectable"
	peripheral_string = identifier(P) * " [" * address(P) * "] " * string(rssi(P)) * " dBm"

	println(peripheral_string, " ", connectable_string)
	println("\tTx Power: ", tx_power(P), " dBm")
	println("\tAddress Type: ", address_type(P))

	for S in services(P)
		println("\tService UUID: ", S.uuid)
		println("\tService data: ", S.data)
	end

	for M in manufacturer_data(P)
		println("\tManufacturer ID: ", M.manufacturer_id)
		println("\tManufacturer data: ", M.data[1:M.data_length])
	end
end
```

## Write

```julia
adapter = get_adapter(0)
peripherals = Peripheral[]
set_callback_on_scan_found(adapter) do peri
	println("Found device: ", identifier(peri), "[",address(peri),"]")
	if is_connectable(peri)
		push!(peripherals, peri)
	end
end
set_callback_on_scan_start(()->println("Scan started"), adapter)
set_callback_on_scan_stop(()->println("Scan stopped"), adapter)
scan_for(5000)

println("The following connectable devices were found")
for (i,p) in enumerate(peripherals)
	println("[$i] ", identifier(p), " [$(address(p))]")
end

print("Please select a device to connect to")
selection = parse(Int, readline())
selection in eachindex(peripherals) || exit(1)

peri = peripherals[selection]
println("Connecting to ", identifier(peri), " [",address(peri),"]")

connect(peri) do 
	println("Successfully connected.")

	uuids = Tuple{SBLEUUID, SBLEUUID}[]
	for S in services(peri)
		for C in S.characteristics
			C.can_indicate || continue
			push!(uuids, (S.uuid, C.uuid))
		end
	end

	for (i, (S,C)) in enumerate(uuids)
		println("[$i] $S $C")
	end

	print("Please select a characteristic to write into")
	selection = parse(Int, readline())
	selection in eachindex(uuids) || error("Incorrect selection")

	println("Please write the contents to be sent: ")
	contents = readline()
	write_request(peri, uuids[selection]..., contents)
end
```