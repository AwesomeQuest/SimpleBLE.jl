export identifier,
	address,
	address_type,
	rssi,
	tx_power,
	mtu,
	connect,
	disconnect,
	is_connected,
	is_connectable,
	is_paired,
	unpair,
	services,
	manufacturer_data,
	peripheral_read,
	write_request,
	write_command,
	notify,
	indicate,
	unsubscribe,
	read_descriptor,
	write_descriptor,
	set_callback_on_connected,
	set_callback_on_disconnected

import Base

### The following are public function intended for users

"""
	identifier(peripheral)
Get the name of a peripheral.

See also [`address`](@ref)
"""
function identifier(peripheral::Peripheral)
	cstr = ccall(
		(:simpleble_peripheral_identifier, simplecble),
		Cstring,
		(SBLEPERIPHERAL, ),
		peripheral
	)
	return finalizer(unsafe_string(cstr)) do x
		# @async @warn "$(time_ns()): Freeing string with value $x"
		free(pointer(cstr))
	end
end

"""
	address(peripheral)
Get the address of a peripheral.

See also [`identifier`](@ref)
"""
function address(peripheral::Peripheral)
	cstr = ccall(
		(:simpleble_peripheral_address, simplecble),
		Cstring,
		(SBLEPERIPHERAL, ),
		peripheral
	)
	return finalizer(unsafe_string(cstr)) do x
		# @async @warn "$(time_ns()): Freeing string with value $x"
		free(pointer(cstr))
	end
end

"`address_type(peripheral)`"
const address_type(peripheral::Peripheral) = ccall(
	(:simpleble_peripheral_address_type, simplecble),
	SBLEADDRESSTYPE,
	(SBLEPERIPHERAL, ),
	peripheral
)

"`rssi(peripheral)`"
const rssi(peripheral::Peripheral) = ccall(
	(:simpleble_peripheral_rssi, simplecble),
	UInt16,
	(SBLEPERIPHERAL, ),
	peripheral
)

"`tx_power(peripheral)`"
const tx_power(peripheral::Peripheral) = ccall(
	(:simpleble_peripheral_tx_power, simplecble),
	UInt16,
	(SBLEPERIPHERAL, ),
	peripheral
)

"`mtu(peripheral)`"
const mtu(peripheral::Peripheral) = ccall(
	(:simpleble_peripheral_mtu, simplecble),
	UInt16,
	(SBLEPERIPHERAL, ),
	peripheral
)

"""
	connect(peripheral)
Connect to a peripheral. Generally you should `disconnect` when you're
done with it
"""
function connect(peripheral::Peripheral)
	err = ccall(
		(:simpleble_peripheral_connect, simplecble),
		SBLEERROR,
		(SBLEPERIPHERAL, ),
		peripheral
	)
	return err == SBLESUCCESS
end

"	disconnect(peripheral)"
function disconnect(peripheral::Peripheral)
	err = ccall(
		(:simpleble_peripheral_disconnect, simplecble),
		SBLEERROR,
		(SBLEPERIPHERAL, ),
		peripheral
	)
	return err == SBLESUCCESS
end

"	is_connected(peripheral)"
function is_connected(peripheral::Peripheral)
	ret = Ref{Bool}()
	err = ccall(
		(:simpleble_peripheral_is_connected, simplecble),
		SBLEERROR,
		(SBLEPERIPHERAL, Ptr{Bool}),
		peripheral, ret
	)
	if err == SBLEFAILURE
		@error "Failed to check connection"
		return nothing
	end
	return ret[]
end

"	is_connectable(peripheral)"
function is_connectable(peripheral::Peripheral)
	ret = Ref{Bool}()
	err = ccall(
		(:simpleble_peripheral_is_connectable, simplecble),
		SBLEERROR,
		(SBLEADAPTER, Ptr{Bool}),
		peripheral, ret
	)
	if err == SBLEFAILURE
		@error "Failed to check scan active"
		return nothing
	end
	return ret[]
end

"	is_paired(peripheral)"
function is_paired(peripheral::Peripheral)
	ret = Ref{Bool}()
	err = ccall(
		(:simpleble_peripheral_is_paired, simplecble),
		SBLEERROR,
		(SBLEADAPTER, Ptr{Bool}),
		peripheral, ret
	)
	if err == SBLEFAILURE
		@error "Failed to check scan active"
		return nothing
	end
	return ret[]
end

"	unpair(peripheral)"
const unpair(peripheral::Peripheral) = ccall(
	(:simpleble_peripheral_unpair, simplecble),
	SBLEERROR, (SBLEPERIPHERAL, ), peripheral
)

"""
	services(peripheral)
Acquire the services provided by a peripheral.
"""
function services(peripheral::Peripheral)
	count = ccall(
		(:simpleble_peripheral_services_count, simplecble),
		Csize_t,
		(SBLEPERIPHERAL, ),
		peripheral
	)
	services = SBLESERVICE[]
	for i in 0:count-1
		ret = Ref{SBLESERVICE}()
		err = ccall(
			(:simpleble_peripheral_services_get, simplecble),
			SBLEERROR, (SBLEPERIPHERAL, Csize_t, Ptr{SBLESERVICE}),
			peripheral, i, ret
		)
		if err == SBLESUCCESS
			push!(services, ret[])
		end
	end
	return services
end

"""
	manufacturer_data(peripheral)
Acquire the manufacturer data associated with peripheral.
"""
function manufacturer_data(peripheral::Peripheral)
	count = ccall(
		(:simpleble_peripheral_manufacturer_data_count, simplecble),
		Csize_t,
		(SBLEPERIPHERAL, ),
		peripheral
	)
	manufacturer_data = SBLEMANUFACTURERDATA[]
	for i in 0:count-1
		ret = Ref{SBLEMANUFACTURERDATA}()
		err = ccall(
			(:simpleble_peripheral_manufacturer_data_get, simplecble),
			SBLEERROR,
			(SBLEPERIPHERAL, Csize_t, Ptr{SBLEMANUFACTURERDATA}),
			peripheral, i, ret
		)
		if err == SBLESUCCESS
			push!(manufacturer_data, ret[])
		end
	end
	return manufacturer_data
end

function peripheral_read(peripheral::Peripheral,
	service::S, characteristic::S) where S <: AbstractString
	s = SBLEUUID(service)
	c = SBLEUUID(characteristic)
	peripheral_read(peripheral, s, c)
end
function peripheral_read(peripheral::Peripheral,
	s::SBLESERVICE, c::SBLECHARACTERISTIC)
	peripheral_read(peripheral, s.uuid, c.uuid)
end

"""
	peripheral_read(peripheral, 
		service::Union{AbstractString, SBLEUUID, SBLESERVICE},
		characteristic::Union{AbstractString, SBLEUUID, SBLECHARACTERISTIC},
	)
Read data from a characteristic.

`service` and `characteristic` can be `AbstractString`s, `SBLEUUID`s, or
`SBLESERVICE` and `SBLECHARACTERISTIC` acquired by `services`.
"""
function peripheral_read(peripheral::Peripheral, s::SBLEUUID, c::SBLEUUID)
	data_ptr = Ref{Ptr{UInt8}}()
	data_length = Ref{Csize_t}()
	err = ccall(
		(:simpleble_peripheral_read, simplecble),
		SBLEERROR, (SBLEPERIPHERAL, SBLEUUID, SBLEUUID, Ptr{Ptr{UInt8}}, Ptr{Csize_t}),
		peripheral, s, c, data_ptr, data_length
	)
	if err == SBLEFAILURE
		@error "Failed to read peripheral"
		return nothing
	end
	return finalizer(unsafe_wrap(Vector{UInt8}, data_ptr[], data_length[])) do
		# @async @warn "Freeing data passed to peripheral_read $(data_ptr[])"
		free(data_ptr[])
	end
end

function write_request(peripheral::Peripheral,
	service::S, characteristic::S, data) where S <: AbstractString
	s = SBLEUUID(service)
	c = SBLEUUID(characteristic)
	write_request(peripheral, s, c, data)
end
function write_request(peripheral::Peripheral,
	s::SBLESERVICE, c::SBLECHARACTERISTIC, data)
	write_request(peripheral, s.uuid, c.uuid, data)
end

"""
	write_request(peripheral,
		service::Union{AbstractString, SBLEUUID, SBLESERVICE},
		characteristic::Union{AbstractString, SBLEUUID, SBLECHARACTERISTIC},
		data <: AbstractArray
	)
Write a request to a characteristic.

See also [`write_command`](@ref)
"""
function write_request(peripheral::Peripheral,
	s::SBLEUUID, c::SBLEUUID, data::Union{A, S}) where {A <: AbstractArray, S <: AbstractString}
	if typeof(data) <: AbstractString
		data = codeunits(data)
	end
	c_data = reinterpret(UInt8, data)
	err = ccall(
		(:simpleble_peripheral_write_request, simplecble),
		SBLEERROR,
		(SBLEPERIPHERAL, SBLEUUID, SBLEUUID, Ptr{UInt8}, Csize_t),
		peripheral, s, c, c_data, length(c_data)
	)
	err == SBLEFAILURE && @error "Failed to write request"
	return err == SBLESUCCESS
end

function write_command(peripheral::Peripheral,
	service::S, characteristic::S, data) where S <: AbstractString
	s = SBLEUUID(service)
	c = SBLEUUID(characteristic)
	write_command(peripheral, s, c, data)
end
function write_command(peripheral::Peripheral,
	s::SBLESERVICE, c::SBLECHARACTERISTIC, data)
	write_command(peripheral, s.uuid, c.uuid, data)
end

"""
	write_command(
		peripheral,
		service::Union{AbstractString, SBLEUUID, SBLESERVICE},
		characteristic::Union{AbstractString, SBLEUUID, SBLECHARACTERISTIC},
		data <: AbstractArray
	)
Write a command to a characteristic.

See also [`write_request`](@ref)
"""
function write_command(peripheral::Peripheral, s::SBLEUUID, c::SBLEUUID, data)
	if typeof(data) <: AbstractString
		data = codeunits(data)
	end
	c_data = reinterpret(UInt8, data)
	err = ccall(
		(:simpleble_peripheral_write_command, simplecble),
		SBLEERROR,
		(SBLEPERIPHERAL, SBLEUUID, SBLEUUID, Ptr{UInt8}, Csize_t),
		peripheral, s, c, c_data, length(c_data)
	)
	return err == SBLESUCCESS
end

# WARNING Do not pass the data anywhere outside the callback, if you need to keep it, copy it
function Base.notify(callback, peripheral::Peripheral,
	service::S, characteristic::S) where S <: AbstractString
	s = SBLEUUID(service)
	c = SBLEUUID(characteristic)
	Base.notify(callback, peripheral, s, c)
end
function Base.notify(callback, peripheral::Peripheral,
	s::SBLESERVICE, c::SBLECHARACTERISTIC)
	Base.notify(callback, peripheral, s.uuid, c.uuid)
end

"""
	notify(callback,
		peripheral::Peripheral,
		service::Union{AbstractString, SBLEUUID, SBLESERVICE},
		characteristic::Union{AbstractString, SBLEUUID, SBLECHARACTERISTIC}
	)
	notify(
		peripheral::Peripheral,
		service::Union{AbstractString, SBLEUUID, SBLESERVICE},
		characteristic::Union{AbstractString, SBLEUUID, SBLECHARACTERISTIC}
	) do data
		# Stuff
	end
Set a callback that is called when data is received from a Characteristic.
`notify` is generally faster than `indicate` because it does not need to
acknowledge that it received the data.

See also [`indicate`](@ref)

!!! warning 
	WARNING: YOU MUST NOT PASS THE `data` VECTOR OUTSIDE THE CALLBACK,
	IT IS NOT VALID AFTER THE CALLBACK FINISHES, IF YOU NEED TO KEEP THE DATA
	AFTER THE CALLBACK IS FINISHED, COPY IT!
"""
function Base.notify(callback, peripheral::Peripheral, s::SBLEUUID, c::SBLEUUID)
	function adjcallback(peripheral, service, characteristic, data, data_length, userdata)
		jldata = unsafe_wrap(Vector{UInt8}, data, data_length)
		wait(errormonitor(@async callback(jldata)), throw=false)
		return nothing
	end
	c_callback = @cfunction($adjcallback,
		Cvoid,
		(SBLEPERIPHERAL, SBLEUUID, SBLEUUID, Ptr{UInt8}, Csize_t, Ptr{Cvoid})
	)
	push!(active_callbacks, c_callback)
	err = ccall(
		(:simpleble_peripheral_notify, simplecble),
		SBLEERROR,
		(SBLEPERIPHERAL, SBLEUUID, SBLEUUID, Ptr{Cvoid}, Ptr{Cvoid}),
		peripheral, s, c, c_callback, C_NULL
	)
	if err == SBLEFAILURE
		@error "Failed to subscribe to notification"
		return nothing
	end
	push!(peripheral.subscriptions, (s,c))
	return nothing
end

# WARNING Do not pass the data anywhere outside the callback, if you need to keep it, copy it
function indicate(callback, peripheral::Peripheral,
	service::S, characteristic::S) where S <: AbstractString
	s = SBLEUUID(service)
	c = SBLEUUID(characteristic)
	indicate(callback, peripheral, s, c)
end
function indicate(callback, peripheral::Peripheral,
	s::SBLESERVICE, c::SBLECHARACTERISTIC)
	indicate(callback, peripheral, s.uuid, c.uuid)
end

"""
	indicate(callback,
		peripheral::Peripheral,
		service::Union{AbstractString, SBLEUUID, SBLESERVICE},
		characteristic::Union{AbstractString, SBLEUUID, SBLECHARACTERISTIC}
	)
	indicate(
		peripheral::Peripheral,
		service::Union{AbstractString, SBLEUUID, SBLESERVICE},
		characteristic::Union{AbstractString, SBLEUUID, SBLECHARACTERISTIC}
	) do data
		# Stuff
	end
Set a callback that is called when data is received from a Characteristic.
`notify` is generally faster than `indicate` because it does not need to
acknowledge that it received the data.

See also [`notify`](@ref)

!!! warning 
	WARNING: YOU MUST NOT PASS THE `data` VECTOR OUTSIDE THE CALLBACK,
	IT IS NOT VALID AFTER THE CALLBACK FINISHES, IF YOU NEED TO KEEP THE DATA
	AFTER THE CALLBACK IS FINISHED, COPY IT!
"""
function indicate(callback, peripheral::Peripheral, s::SBLEUUID, c::SBLEUUID)
	function adjcallback(peripheral, service, characteristic, data, data_length, userdata)
		jldata = unsafe_wrap(Vector{UInt8}, data, data_length)
		wait(errormonitor(@async callback(jldata)), throw=false)
		return nothing
	end
	c_callback = @cfunction($adjcallback,
		Cvoid,
		(SBLEPERIPHERAL, SBLEUUID, SBLEUUID, Ptr{UInt8}, Csize_t, Ptr{Cvoid})
	)
	push!(active_callbacks, c_callback)
	err= ccall(
		(:simpleble_peripheral_indicate, simplecble),
		SBLEERROR,
		(SBLEPERIPHERAL, SBLEUUID, SBLEUUID, Ptr{Cvoid}, Ptr{Cvoid}),
		peripheral, s, c, c_callback, C_NULL
	)
	if err == SBLEFAILURE
		@error "Failed to subscribe to notification"
		return nothing
	end
	push!(peripheral.subscriptions, (s,c))
	return nothing
end

function unsubscribe(peripheral::Peripheral,
	service::S, characteristic::S) where S <: AbstractString
	s = SBLEUUID(service)
	c = SBLEUUID(characteristic)
	unsubscribe(peripheral, s, c)
end
function unsubscribe(peripheral::Peripheral, s::SBLESERVICE, c::SBLECHARACTERISTIC)
	unsubscribe(peripheral, s.uuid, c.uuid)
end

"""
	unsubscribe(
		peripheral,
		service::Union{AbstractString, SBLEUUID, SBLESERVICE},
		characteristic::Union{AbstractString, SBLEUUID, SBLECHARACTERISTIC}
	)
unsubscribe from a [`notify`](@ref) or [`indicate`](@ref) call.
"""
function unsubscribe(peripheral::Peripheral, s::SBLEUUID, c::SBLEUUID)
	err = ccall(
		(:simpleble_peripheral_unsubscribe, simplecble),
		SBLEERROR,
		(SBLEPERIPHERAL, SBLEUUID, SBLEUUID),
		peripheral, s, c
	)
	if err == SBLEFAILURE
		@error "Failed to subscribe to notification"
		return nothing
	end
	delete!(peripheral.subscriptions, (s,c))
	return nothing
end

function read_descriptor(peripheral::Peripheral,
	service::S, characteristic::S, descriptor::S) where S <: AbstractString
	s = SBLEUUID(service)
	c = SBLEUUID(characteristic)
	d = SBLEUUID(descriptor)
	read_descriptor(peripheral, s, c, d)
end
function read_descriptor(peripheral::Peripheral,
	s::SBLESERVICE, c::SBLECHARACTERISTIC, d::SBLEDESCRIPTOR)
	read_descriptor(peripheral, s.uuid, c.uuid, d.uuid)
end

"""
	read_descriptor(
		peripheral,
		service::Union{AbstractString, SBLEUUID, SBLESERVICE},
		characteristic::Union{AbstractString, SBLEUUID, SBLECHARACTERISTIC},
		descriptor::Union{AbstractString, SBLEUUID, SBLECHARACTERISTIC}
	)
Read data from a descriptor.
"""
function read_descriptor(peripheral::Peripheral,
	s::SBLEUUID, c::SBLEUUID, d::SBLEUUID)
	data_ptr = Ref{Ptr{UInt8}}()
	data_length = Ref{Csize_t}()
	err = ccall(
		(:simpleble_peripheral_read_descriptor, simplecble),
		SBLEERROR,
		(SBLEPERIPHERAL, SBLEUUID, SBLEUUID, SBLEUUID, Ptr{Ptr{UInt8}}, Ptr{Csize_t}),
		peripheral, s, c, d, data_ptr, data_length
	)
	if err == SBLEFAILURE
		@error "Failed to read peripheral"
		return nothing
	end
	return unsafe_wrap(Vector{UInt8}, data_ptr[], data_length[])
end

function write_descriptor(peripheral::Peripheral,
	service::S, characteristic::S, descriptor::S, data) where S <: AbstractString
	s = SBLEUUID(service)
	c = SBLEUUID(characteristic)
	d = SBLEUUID(descriptor)
	write_descriptor(peripheral, s, c, d, data)
end
function write_descriptor(peripheral::Peripheral,
	s::SBLESERVICE, c::SBLECHARACTERISTIC, d::SBLEDESCRIPTOR, data)
	write_descriptor(peripheral, s.uuid, c.uuid, d.uuid, data)
end

"""
	write_descriptor(
		peripheral,
		service::Union{AbstractString, SBLEUUID, SBLESERVICE},
		characteristic::Union{AbstractString, SBLEUUID, SBLECHARACTERISTIC},
		descriptor::Union{AbstractString, SBLEUUID, SBLECHARACTERISTIC},
		data <: AbstractArray
	)
Write data to a descriptor.
"""
function write_descriptor(peripheral::Peripheral,
	s::SBLEUUID, c::SBLEUUID, d::SBLEUUID, data)
	if typeof(data) <: AbstractString
		data = codeunits(data)
	end
	c_data = reinterpret(UInt8, data)
	err = ccall(
		(:simpleble_peripheral_write_descriptor, simplecble),
		SBLEERROR,
		(SBLEPERIPHERAL, SBLEUUID, SBLEUUID, SBLEUUID, Ptr{UInt8}, Csize_t),
		peripheral, s, c, d, c_data, length(c_data)
	)
	return err == SBLESUCCESS
end

"""
	set_callback_on_connected(callback, peripheral)
	set_callback_on_connected(peripheral) do
		# Stuff
	end

Set a callback that is called when a peripheral is connected.

See also [`set_callback_on_disconnected`](@ref)
"""
function set_callback_on_connected(callback, peripheral::Peripheral)
	function adjcallback(peripheral, userdata)
		wait(errormonitor(@async callback()); throw=false)
		return nothing
	end
	c_callback = @cfunction($adjcallback, Cvoid, (SBLEPERIPHERAL, Ptr{Cvoid}))
	push!(active_callbacks, c_callback)
	err = ccall(
		(:simpleble_peripheral_set_callback_on_connected, simplecble),
		SBLEERROR,
		(SBLEPERIPHERAL, Ptr{Cvoid}, Ptr{Cvoid}),
		peripheral, c_callback, C_NULL
	)
	err != SBLESUCCESS && @error "Assigning callback failed"
	return nothing
end

"""
	set_callback_on_disconnected(callback, peripheral)
	set_callback_on_disconnected(peripheral) do
		# Stuff
	end
Set a callback that is called when a peripheral is disconnected.

See also [`set_callback_on_connected`](@ref)
"""
function set_callback_on_disconnected(callback, peripheral::Peripheral)
	function adjcallback(peripheral, userdata)
		wait(errormonitor(@async callback()); throw=false)
		return nothing
	end
	c_callback = @cfunction($adjcallback, Cvoid, (SBLEPERIPHERAL, Ptr{Cvoid}))
	push!(active_callbacks, c_callback)
	err = ccall(
		(:simpleble_peripheral_set_callback_on_disconnected, simplecble),
		SBLEERROR,
		(SBLEPERIPHERAL, Ptr{Cvoid}, Ptr{Cvoid}),
		peripheral, c_callback, C_NULL
	)
	err != SBLESUCCESS && @error "Assigning callback failed"
	return nothing
end

### The following are internal and not sanitized for users
"`simpleble_peripheral_underlying(handle)`"
simpleble_peripheral_underlying(handle) = ccall(
	(:simpleble_peripheral_underlying, simplecble),
	Ptr{Cvoid},
	(SBLEPERIPHERAL, ),
	handle
)