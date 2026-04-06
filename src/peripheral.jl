export identifier,
	address,
	connect,
	disconnect,
	isconnected,
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

### The following are public function inteded for users


function identifier(peripheral::Peripheral)
	cstr = ccall((:simpleble_peripheral_identifier, :simplecble), Cstring, (SBLEPERIPHERAL, ), peripheral)
	return finalizer(unsafe_string(cstr)) do x
		# @async @warn "$(time_ns()): Freeing string with value $x"
		free(pointer(cstr))
	end
end

function address(peripheral::Peripheral)
	cstr = ccall((:simpleble_peripheral_address, :simplecble), Cstring, (SBLEPERIPHERAL, ), peripheral)
	return finalizer(unsafe_string(cstr)) do x
		# @async @warn "$(time_ns()): Freeing string with value $x"
		free(pointer(cstr))
	end
end

function connect(peripheral::Peripheral)
	err = ccall((:simpleble_peripheral_connect, :simplecble), SBLEERROR, (SBLEPERIPHERAL, ), peripheral)
	return err == SBLESUCCESS
end

function disconnect(peripheral::Peripheral)
	err = ccall((:simpleble_peripheral_disconnect, :simplecble), SBLEERROR, (SBLEPERIPHERAL, ), peripheral)
	return err == SBLESUCCESS
end

function isconnected(peripheral::Peripheral)
	ret = Ref{Bool}()
	err = ccall((:simpleble_peripheral_is_connected, :simplecble), SBLEERROR, (SBLEPERIPHERAL, Ptr{Bool}), peripheral, ret)
	if err == SBLEFAILURE
		@error "Failed to read peripheral"
		return nothing
	end
	return ret[]
end

function peripheral_read(peripheral::Peripheral, service::S, characteristic::S) where S <: AbstractString
	s = SBLEUUID(service)
	c = SBLEUUID(characteristic)
	data_ptr = Ref{Ptr{UInt8}}()
	data_length = Ref{Csize_t}()
	err = ccall((:simpleble_peripheral_read, :simplecble), SBLEERROR, (SBLEPERIPHERAL, SBLEUUID, SBLEUUID, Ptr{Ptr{UInt8}}, Ptr{Csize_t}), peripheral, s, c, data_ptr, data_length)
	if err == SBLEFAILURE
		@error "Failed to read peripheral"
		return nothing
	end
	return finalizer(unsafe_wrap(Vector{UInt8}, data_ptr[], data_length[])) do
		# @async @warn "Freeing data passed to peripheral_read $(data_ptr[])"
		free(data_ptr[])
	end
end

function write_request(peripheral::Peripheral, service::S, characteristic::S, data) where S <: AbstractString
	s = SBLEUUID(service)
	c = SBLEUUID(characteristic)
	if typeof(data) <: AbstractString
		data = codeunits(data)
	end
	err = ccall((:simpleble_peripheral_write_request, :simplecble), SBLEERROR, (SBLEPERIPHERAL, SBLEUUID, SBLEUUID, Ptr{UInt8}), peripheral, s, c, data)
	return err == SBLESUCCESS
end

function write_command(peripheral::Peripheral, service::S, characteristic::S, data) where S <: AbstractString
	s = SBLEUUID(service)
	c = SBLEUUID(characteristic)
	if typeof(data) <: AbstractString
		data = codeunits(data)
	end
	err = ccall((:simpleble_peripheral_write_command, :simplecble), SBLEERROR, (SBLEPERIPHERAL, SBLEUUID, SBLEUUID, Ptr{UInt8}), peripheral, s, c, data)
	return err == SBLESUCCESS
end

function Base.notify(callback, peripheral::Peripheral, service::S, characteristic::S) where S <: AbstractString
	s = SBLEUUID(service)
	c = SBLEUUID(characteristic)
	function adjcallback(peripheral, service, characteristic, data, data_length, userdata)
		jldata = unsafe_wrap(Vector{UInt8}, data, data_length)
		wait(errormonitor(@async callback(jldata)), throw=false)
		return nothing
	end
	c_callback = @cfunction($adjcallback, Cvoid, (SBLEPERIPHERAL, SBLEUUID, SBLEUUID, Ptr{UInt8}, Csize_t, Ptr{Cvoid}))
	push!(active_callbacks, c_callback)
	err= ccall((:simpleble_peripheral_notify, :simplecble), SBLEERROR, (SBLEPERIPHERAL, SBLEUUID, SBLEUUID, Ptr{Cvoid}, Ptr{Cvoid}), peripheral, s, c, c_callback, C_NULL)
	if err == SBLEFAILURE
		@error "Failed to subscribe to notification"
		return nothing
	end
	push!(peripheral.subscriptions, (s,c))
	return nothing
end

function indicate(callback, peripheral::Peripheral, service::S, characteristic::S) where S <: AbstractString
	s = SBLEUUID(service)
	c = SBLEUUID(characteristic)
	function adjcallback(peripheral, service, characteristic, data, data_length, userdata)
		jldata = unsafe_wrap(Vector{UInt8}, data, data_length)
		wait(errormonitor(@async callback(jldata)), throw=false)
		return nothing
	end
	c_callback = @cfunction($adjcallback, Cvoid, (SBLEPERIPHERAL, SBLEUUID, SBLEUUID, Ptr{UInt8}, Csize_t, Ptr{Cvoid}))
	push!(active_callbacks, c_callback)
	err= ccall((:simpleble_peripheral_indicate, :simplecble), SBLEERROR, (SBLEPERIPHERAL, SBLEUUID, SBLEUUID, Ptr{Cvoid}, Ptr{Cvoid}), peripheral, s, c, c_callback, C_NULL)
	if err == SBLEFAILURE
		@error "Failed to subscribe to notification"
		return nothing
	end
	push!(peripheral.subscriptions, (s,c))
	return nothing
end

function unsubscribe(peripheral::Peripheral, service::S, characteristic::S) where S <: AbstractString
	s = SBLEUUID(service)
	c = SBLEUUID(characteristic)
	err = ccall((:simpleble_peripheral_unsubscribe, :simplecble), SBLEERROR, (SBLEPERIPHERAL, SBLEUUID, SBLEUUID), peripheral, s, c)
	if err == SBLEFAILURE
		@error "Failed to subscribe to notification"
		return nothing
	end
	delete!(peripheral.subscriptions, (s,c))
	return nothing
end

function read_descriptor(peripheral::Peripheral, service::S, characteristic::S, descriptor::S) where S <: AbstractString
	s = SBLEUUID(service)
	c = SBLEUUID(characteristic)
	d = SBLEUUID(descriptor)
	data_ptr = Ref{Ptr{UInt8}}()
	data_length = Ref{Csize_t}()
	err = ccall((:simpleble_peripheral_read_descriptor, :simplecble), SBLEERROR, (SBLEPERIPHERAL, SBLEUUID, SBLEUUID, SBLEUUID, Ptr{Ptr{UInt8}}, Ptr{Csize_t}), peripheral, s, c, d, data_ptr, data_length)
	if err == SBLEFAILURE
		@error "Failed to read peripheral"
		return nothing
	end
	return unsafe_wrap(Vector{UInt8}, data_ptr[], data_length[])
end

function write_descriptor(peripheral::Peripheral, service::S, characteristic::S, descriptor::S, data) where S <: AbstractString
	s = SBLEUUID(service)
	c = SBLEUUID(characteristic)
	d = SBLEUUID(descriptor)
	if typeof(data) <: AbstractString
		data = codeunits(data)
	end
	err = ccall((:simpleble_peripheral_write_descriptor, :simplecble), SBLEERROR, (SBLEPERIPHERAL, SBLEUUID, SBLEUUID, SBLEUUID, Ptr{UInt8}), peripheral, s, c, d, data)
	return err == SBLESUCCESS
end

function set_callback_on_connected(callback, peripheral::Adapter)
	function adjcallback(peripheral, userdata)
		wait(errormonitor(@async callback()); throw=false)
		return nothing
	end
	c_callback = @cfunction($adjcallback, Cvoid, (SBLEPERIPHERAL, Ptr{Cvoid}))
	push!(active_callbacks, c_callback)
	err = ccall((:simpleble_peripheral_set_callback_on_connected, :simplecble), SBLEERROR, (SBLEPERIPHERAL, Ptr{Cvoid}, Ptr{Cvoid}), peripheral, c_callback, C_NULL)
	err != SBLESUCCESS && @error "Assigning callback failed"
	return nothing
end

function set_callback_on_disconnected(callback, peripheral::Adapter)
	function adjcallback(peripheral, userdata)
		wait(errormonitor(@async callback()); throw=false)
		return nothing
	end
	c_callback = @cfunction($adjcallback, Cvoid, (SBLEPERIPHERAL, Ptr{Cvoid}))
	push!(active_callbacks, c_callback)
	err = ccall((:simpleble_peripheral_set_callback_on_disconnected, :simplecble), SBLEERROR, (SBLEPERIPHERAL, Ptr{Cvoid}, Ptr{Cvoid}), peripheral, c_callback, C_NULL)
	err != SBLESUCCESS && @error "Assigning callback failed"
	return nothing
end

### The following are internal and not sanitized for users

simpleble_peripheral_underlying(handle) = ccall((:simpleble_peripheral_underlying, :simplecble), Ptr{Cvoid}, (SBLEPERIPHERAL, ), handle)
simpleble_peripheral_address_type(handle) = ccall((:simpleble_peripheral_address_type, :simplecble), SBLEADDRESSTYPE, (SBLEPERIPHERAL, ), handle)
simpleble_peripheral_rssi(handle) = ccall((:simpleble_peripheral_rssi, :simplecble), UInt16, (SBLEPERIPHERAL, ), handle)
simpleble_peripheral_tx_power(handle) = ccall((:simpleble_peripheral_tx_power, :simplecble), UInt16, (SBLEPERIPHERAL, ), handle)
simpleble_peripheral_mtu(handle) = ccall((:simpleble_peripheral_mtu, :simplecble), UInt16, (SBLEPERIPHERAL, ), handle)
simpleble_peripheral_is_connectable(handle, ret) = ccall((:simpleble_peripheral_is_connectable, :simplecble), SBLEERROR, (SBLEPERIPHERAL, Ptr{Bool}), handle, ret)
simpleble_peripheral_is_paired(handle, ret) = ccall((:simpleble_peripheral_is_paired, :simplecble), SBLEERROR, (SBLEPERIPHERAL, Ptr{Bool}), handle, ret)
simpleble_peripheral_unpair(handle) = ccall((:simpleble_peripheral_unpair, :simplecble), SBLEERROR, (SBLEPERIPHERAL, ), handle)
simpleble_peripheral_services_count(handle) = ccall((:simpleble_peripheral_services_count, :simplecble), Csize_t, (SBLEPERIPHERAL, ), handle)
simpleble_peripheral_services_get(handle, index, ret) = ccall((:simpleble_peripheral_services_get, :simplecble), SBLEERROR, (SBLEPERIPHERAL, Csize_t, Ptr{SBLESERVICE}), handle, index, ret)
simpleble_peripheral_manufacturer_data_count(handle) = ccall((:simpleble_peripheral_manufacturer_data_count, :simplecble), Csize_t, (SBLEPERIPHERAL, ), handle)
simpleble_peripheral_manufacturer_data_get(handle, index, ret) = ccall((:simpleble_peripheral_manufacturer_data_get, :simplecble), SBLEERROR, (SBLEPERIPHERAL, Csize_t, Ptr{SBLEMANUFACTURERDATA}), handle, index, ret)
