using SimpleBLE


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






