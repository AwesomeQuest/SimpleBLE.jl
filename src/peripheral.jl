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
	cstr = @ccall sbledir().simpleble_peripheral_identifier(peripheral::SBLEPERIPHERAL)::Cstring
	return finalizer(unsafe_string(cstr)) do x
		# @async @warn "$(time_ns()): Freeing string with value $x"
		free(pointer(cstr))
	end
end

function address(peripheral::Peripheral)
	cstr = @ccall sbledir().simpleble_peripheral_address(peripheral::SBLEPERIPHERAL)::Cstring
	return finalizer(unsafe_string(cstr)) do x
		# @async @warn "$(time_ns()): Freeing string with value $x"
		free(pointer(cstr))
	end
end

function connect(peripheral::Peripheral)
	err = @ccall sbledir().simpleble_peripheral_connect(peripheral::SBLEPERIPHERAL)::SBLEERROR
	return err == SBLESUCCESS
end

function disconnect(peripheral::Peripheral)
	err = @ccall sbledir().simpleble_peripheral_disconnect(peripheral::SBLEPERIPHERAL)::SBLEERROR
	return err == SBLESUCCESS
end

function isconnected(peripheral::Peripheral)
	ret = Ref{Bool}()
	err = @ccall sbledir().simpleble_peripheral_is_connected(peripheral::SBLEPERIPHERAL, ret::Ptr{Bool})::SBLEERROR
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
	err = @ccall sbledir().simpleble_peripheral_read(peripheral::SBLEPERIPHERAL, s::SBLEUUID, c::SBLEUUID, data_ptr::Ptr{Ptr{UInt8}}, data_length::Ptr{Csize_t})::SBLEERROR
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
	err = @ccall sbledir().simpleble_peripheral_write_request(peripheral::SBLEPERIPHERAL, s::SBLEUUID, c::SBLEUUID, data::Ptr{UInt8}, length(data)::Csize_t)::SBLEERROR
	return err == SBLESUCCESS
end

function write_command(peripheral::Peripheral, service::S, characteristic::S, data) where S <: AbstractString
	s = SBLEUUID(service)
	c = SBLEUUID(characteristic)
	if typeof(data) <: AbstractString
		data = codeunits(data)
	end
	err = @ccall sbledir().simpleble_peripheral_write_command(peripheral::SBLEPERIPHERAL, s::SBLEUUID, c::SBLEUUID, data::Ptr{UInt8}, length(data)::Csize_t)::SBLEERROR
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
	err= @ccall sbledir().simpleble_peripheral_notify(peripheral::SBLEPERIPHERAL, s::SBLEUUID, c::SBLEUUID, c_callback::Ptr{Cvoid}, C_NULL::Ptr{Cvoid})::SBLEERROR
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
	err= @ccall sbledir().simpleble_peripheral_indicate(peripheral::SBLEPERIPHERAL, s::SBLEUUID, c::SBLEUUID, c_callback::Ptr{Cvoid}, C_NULL::Ptr{Cvoid})::SBLEERROR
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
	err = @ccall sbledir().simpleble_peripheral_unsubscribe(peripheral::SBLEPERIPHERAL, s::SBLEUUID, c::SBLEUUID)::SBLEERROR
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
	err = @ccall sbledir().simpleble_peripheral_read_descriptor(peripheral::SBLEPERIPHERAL, s::SBLEUUID, c::SBLEUUID, d::SBLEUUID, data_ptr::Ptr{Ptr{UInt8}}, data_length::Ptr{Csize_t})::SBLEERROR
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
	err = @ccall sbledir().simpleble_peripheral_write_descriptor(peripheral::SBLEPERIPHERAL, s::SBLEUUID, c::SBLEUUID, d::SBLEUUID, data::Ptr{UInt8}, length(data)::Csize_t)::SBLEERROR
	return err == SBLESUCCESS
end

function set_callback_on_connected(callback, peripheral::Adapter)
	function adjcallback(peripheral, userdata)
		wait(errormonitor(@async callback()); throw=false)
		return nothing
	end
	c_callback = @cfunction($adjcallback, Cvoid, (SBLEPERIPHERAL, Ptr{Cvoid}))
	push!(active_callbacks, c_callback)
	err = @ccall sbledir().simpleble_peripheral_set_callback_on_connected(peripheral::SBLEPERIPHERAL, c_callback::Ptr{Cvoid}, C_NULL::Ptr{Cvoid})::SBLEERROR
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
	err = @ccall sbledir().simpleble_peripheral_set_callback_on_disconnected(peripheral::SBLEPERIPHERAL, c_callback::Ptr{Cvoid}, C_NULL::Ptr{Cvoid})::SBLEERROR
	err != SBLESUCCESS && @error "Assigning callback failed"
	return nothing
end

### The following are internal and not sanitized for users

simpleble_peripheral_underlying(handle) = @ccall sbledir().simpleble_peripheral_underlying(handle::SBLEPERIPHERAL)::Ptr{Cvoid}
simpleble_peripheral_address_type(handle) = @ccall sbledir().simpleble_peripheral_address_type(handle::SBLEPERIPHERAL)::SBLEADDRESSTYPE
simpleble_peripheral_rssi(handle) = @ccall sbledir().simpleble_peripheral_rssi(handle::SBLEPERIPHERAL)::UInt16
simpleble_peripheral_tx_power(handle) = @ccall sbledir().simpleble_peripheral_tx_power(handle::SBLEPERIPHERAL)::UInt16
simpleble_peripheral_mtu(handle) = @ccall sbledir().simpleble_peripheral_mtu(handle::SBLEPERIPHERAL)::UInt16
simpleble_peripheral_is_connectable(handle, ret) = @ccall sbledir().simpleble_peripheral_is_connectable(handle::SBLEPERIPHERAL, ret::Ptr{Bool})::SBLEERROR
simpleble_peripheral_is_paired(handle, ret) = @ccall sbledir().simpleble_peripheral_is_paired(handle::SBLEPERIPHERAL, ret::Ptr{Bool})::SBLEERROR
simpleble_peripheral_unpair(handle) = @ccall sbledir().simpleble_peripheral_unpair(handle::SBLEPERIPHERAL)::SBLEERROR
simpleble_peripheral_services_count(handle) = @ccall sbledir().simpleble_peripheral_services_count(handle::SBLEPERIPHERAL)::Csize_t
simpleble_peripheral_services_get(handle, index, ret) = @ccall sbledir().simpleble_peripheral_services_get(handle::SBLEPERIPHERAL, index::Csize_t, ret::Ptr{SBLESERVICE})::SBLEERROR
simpleble_peripheral_manufacturer_data_count(handle) = @ccall sbledir().simpleble_peripheral_manufacturer_data_count(handle::SBLEPERIPHERAL)::Csize_t
simpleble_peripheral_manufacturer_data_get(handle, index, ret) = @ccall sbledir().simpleble_peripheral_manufacturer_data_get(handle::SBLEPERIPHERAL, index::Csize_t, ret::Ptr{SBLEMANUFACTURERDATA})::SBLEERROR
