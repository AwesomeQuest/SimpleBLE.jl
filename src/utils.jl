
import Base

export Characteristic,
	get_adapter,
	get_service_uuids,
	find_peripheral,
	connect_peripheral,
	connect,
	disconnect,
	write_request


struct Characteristic
	serviceuuid::SBLEUUID
	uuid::SBLEUUID
	Characteristic(charuuid, serviceuuid) = new(SBLEUUID(charuuid), SBLEUUID(serviceuuid))
end

function Base.write(peripheral::SBLEPeripheral, characteristic::Characteristic, data; type=:request)
	if type === :request
		err = peripheral_write_request(peripheral, characteristic.serviceuuid, characteristic.uuid, data)
		err != SIMPLEBLE_SUCCESS && @error "Failed to write to Characteristic: $characteristic"
	elseif type === :command
		peripheral_write_command(peripheral, characteristic.serviceuuid, characteristic.uuid, data)
		err != SIMPLEBLE_SUCCESS && @error "Failed to write to Characteristic: $characteristic"
	else
		error(ArgumentError("Unrecognized type $type"))
	end
	return nothing
end
function Base.read(peripheral::SBLEPeripheral, characteristic::Characteristic)
	data_ptr = Ref{Ptr{UInt8}}()
	data_length = Ref{Csize_t}()
	readerr = peripheral_read(peripheral, characteristic.serviceuuid, characteristic.uuid, data_ptr, data_length)
	readerr == SimpleBLE_Error && @error("Failed to read")
	return finalizer(unsafe_wrap(Vector{UInt8}, data_ptr[], data_length[])) do x
		simpleble_free(data_ptr[])
	end
end

function get_adapter(index=0) # Windows only supports 1 adapter
	adapter_get_count() == 0 && error("No adapter was found.")

	adapter = adapter_get_handle(0)
	adapter == C_NULL && error("No adapter was found.")
	adapter
end

function get_service_uuids(peripheral)
	uuids = SBLEUUID[]
	servref = Ref{SBLEService}()
	for i in 0:peripheral_services_count(peripheral)-1
		peripheral_services_get(peripheral, i, servref) != SIMPLEBLE_SUCCESS && continue
		push!(uuids, servref[].uuid)
	end
	return uuids
end

function find_peripheral(matchfunc, adapter; scantime=5_000, maxretrys = 5)

	foundmatchchannel = Channel{Bool}(Inf)
	adapter_set_callback_on_scan_start(adapter, 
		(adapter,y)->println("Adapter $(adapter_identifier(adapter)) started scanning."), 
		C_NULL
	)
	adapter_set_callback_on_scan_stop(adapter, 
		(adapter,y)->println("Adapter $(adapter_identifier(adapter)) stopped scanning."), 
		C_NULL
	)
	adapter_set_callback_on_scan_found(adapter, 
		(adapter,peripheral,z)->begin
			aid = adapter_identifier(adapter)
			pid = peripheral_identifier(peripheral)
			pad = peripheral_address(peripheral)
			println("Adapter $aid found device $pid [$pad].")
			if matchfunc(peripheral)
				println("Found peripheral")
				put!(foundmatchchannel, true)
			end
			return nothing
		end,
		C_NULL
	)
	adapter_set_callback_on_scan_updated(adapter, 
		(adapter,peripheral,z)->begin
			aid = adapter_identifier(adapter)
			pid = peripheral_identifier(peripheral)
			pad = peripheral_address(peripheral)
			println("Adapter $aid updated device $pid [$pad].")
			if matchfunc(peripheral)
				println("Found peripheral")
				put!(foundmatchchannel, true)
			end
			return nothing
		end, 
		C_NULL
	)

	adapter_scan_start(adapter)

	println("Waiting for right peripheral")
	take!(foundmatchchannel)
	adapter_scan_stop(adapter)
	sleep(1)
	close(foundmatchchannel)
	for i in 0:adapter_scan_get_results_count(adapter)-1
		peripheral = adapter_scan_get_results_handle(adapter, i)
		matchfunc(peripheral) && return peripheral
	end
	error("Failed to find peripheral")
end

function connect(peripheral)
	periconectable = Ref(false)
	if peripheral_is_connectable(peripheral, periconectable) != SIMPLEBLE_SUCCESS
		error("Failed to assess connectability of peripheral $peripheral")
	end
	!periconectable[] && return false
	if peripheral_connect(peripheral) != SIMPLEBLE_SUCCESS
		error("Failed to connect to peripheral $peripheral")
	end
	return true
end

function disconnect(peripheral)
	peripheral_disconnect(peripheral) != SimpleBLE_Error
end

function connect(func, peripheral)
	connect(peripheral)
	try
		func(peripheral)
	catch e
		throw(e)
	finally
		disconnect(peripheral)
	end
end

function connect_peripheral(func, matchperipheral)
	adapter = get_adapter()
	peripheral = find_peripheral(matchperipheral, adapter)
	connect(peripheral)
	try
		func(peripheral)
	catch e
		@error e
	finally
		while !disconnect(peripheral) sleep(1) end
		# peripheral_release_handle(peripheral)
		# adapter_release_handle(adapter)
	end
end


function write_request(peripheral::SBLEPeripheral, SERVICE_UUID::T, CHARACTERISTIC_UUID_RX::T, data) where T <: AbstractString
	peripheral_write_request(peripheral, SBLEUUID(SERVICE_UUID), SBLEUUID(CHARACTERISTIC_UUID_RX), data)
end