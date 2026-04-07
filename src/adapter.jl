export get_adapter,
	identifier,
	address,
	set_callback_on_power_on,
	set_callback_on_power_off,
	scan_start,
	scan_stop,
	set_callback_on_scan_start,
	set_callback_on_scan_stop,
	set_callback_on_scan_found,
	set_callback_on_scan_updated


### The following are public function inteded for users

function get_adapter(i)
	adapter = ccall((:simpleble_adapter_get_handle, :simplecble), Ptr{Cvoid}, (Csize_t, ), i)
	push!(adapters, adapter)
	return adapter
end

function identifier(adapter::Adapter)
	cstr = ccall((:simpleble_adapter_identifier, :simplecble), Cstring, (SBLEADAPTER, ), adapter)
	return finalizer(unsafe_string(cstr)) do x
		# @async @warn "$(time_ns()): Freeing string with value $x"
		free(pointer(cstr))
	end
end

function address(peripheral::Adapter)
	cstr = ccall((:simpleble_adapter_address, :simplecble), Cstring, (SBLEADAPTER, ), peripheral)
	return finalizer(unsafe_string(cstr)) do x
		# @async @warn "$(time_ns()): Freeing string with value $x"
		free(pointer(cstr))
	end
end

function set_callback_on_power_on(callback, adapter::Adapter)
	function adjcallback(adapter, userdata)
		wait(errormonitor(@async callback()); throw=false)
		return nothing
	end
	c_callback = @cfunction($adjcallback, Cvoid, (SBLEADAPTER, Ptr{Cvoid}))
	push!(active_callbacks, c_callback)
	err = ccall((:simpleble_adapter_set_callback_on_power_on, :simplecble), SBLEERROR, (SBLEADAPTER, Ptr{Cvoid}, Ptr{Cvoid}), adapter, c_callback, C_NULL)
	err != SBLESUCCESS && @error "Assigning callback failed"
	return nothing
end

function set_callback_on_power_off(callback, adapter::Adapter)
	function adjcallback(adapter, userdata)
		wait(errormonitor(@async callback()); throw=false)
		return nothing
	end
	c_callback = @cfunction($adjcallback, Cvoid, (SBLEADAPTER, Ptr{Cvoid}))
	push!(active_callbacks, c_callback)
	err = ccall((:simpleble_adapter_set_callback_on_power_off, :simplecble), SBLEERROR, (SBLEADAPTER, Ptr{Cvoid}, Ptr{Cvoid}), adapter, c_callback, C_NULL)
	err != SBLESUCCESS && @error "Assigning callback failed"
	return nothing
end

function scan_start(adapter::Adapter)
	err = ccall((:simpleble_adapter_scan_start, :simplecble), SBLEERROR, (SBLEADAPTER, ), adapter)
	err == SBLEFAILURE && @error "Failed to start scan"
	return nothing
end

function scan_stop(adapter::Adapter)
	err = ccall((:simpleble_adapter_scan_stop, :simplecble), SBLEERROR, (SBLEADAPTER, ), adapter)
	err == SBLEFAILURE && @error "Failed to stop scan"
	return nothing
end

function scan_for(adapter::Adapter, timeout_ms)
	err = ccall((:simpleble_adapter_scan_for, :simplecble), SBLEERROR, (SBLEADAPTER, Cint), adapter, timeout_ms)
	err == SBLEFAILURE && @error "Failed to scan for $timeout_ms ms"
	return nothing
end

function set_callback_on_scan_start(callback, adapter::Adapter)
	function adjcallback(adapter, userdata)
		wait(errormonitor(@async callback()); throw=false)
		return nothing
	end
	c_callback = @cfunction($adjcallback, Cvoid, (SBLEADAPTER, Ptr{Cvoid}))
	push!(active_callbacks, c_callback)
	err = ccall((:simpleble_adapter_set_callback_on_scan_start, :simplecble), SBLEERROR, (SBLEADAPTER, Ptr{Cvoid}, Ptr{Cvoid}), adapter, c_callback, C_NULL)
	err != SBLESUCCESS && @error "Assigning callback failed"
	return nothing
end

function set_callback_on_scan_stop(callback, adapter::Adapter)
	function adjcallback(adapter, userdata)
		wait(errormonitor(@async callback()); throw=false)
		return nothing
	end
	c_callback = @cfunction($adjcallback, Cvoid, (SBLEADAPTER, Ptr{Cvoid}))
	push!(active_callbacks, c_callback)
	err = ccall((:simpleble_adapter_set_callback_on_scan_stop, :simplecble), SBLEERROR, (SBLEADAPTER, Ptr{Cvoid}, Ptr{Cvoid}), adapter, c_callback, C_NULL)
	err != SBLESUCCESS && @error "Assigning callback failed"
	return nothing
end

function set_callback_on_scan_found(callback, adapter::Adapter)
	function adjcallback(adapter, peripheral, userdata)
		P = Peripheral(peripheral)
		# TODO Maybe GC preserve P
		wait(errormonitor(@async callback(P)); throw=false)
		return nothing
	end
	c_callback = @cfunction($adjcallback, Cvoid, (SBLEADAPTER, SBLEPERIPHERAL, Ptr{Cvoid}))
	push!(active_callbacks, c_callback)
	err = ccall((:simpleble_adapter_set_callback_on_scan_found, :simplecble), SBLEERROR, (SBLEADAPTER, Ptr{Cvoid}, Ptr{Cvoid}), adapter, c_callback, C_NULL)
	err != SBLESUCCESS && @error "Assigning callback failed"
	return nothing
end

function set_callback_on_scan_updated(callback, adapter::Adapter)
	function adjcallback(adapter, peripheral, userdata)
		P = Peripheral(peripheral)
		# TODO Maybe GC preserve P
		wait(errormonitor(@async callback(P)); throw=false)
		return nothing
	end
	c_callback = @cfunction($adjcallback, Cvoid, (SBLEADAPTER, SBLEPERIPHERAL, Ptr{Cvoid}))
	push!(active_callbacks, c_callback)
	err = ccall((:simpleble_adapter_set_callback_on_scan_updated, :simplecble), SBLEERROR, (SBLEADAPTER, Ptr{Cvoid}), adapter, c_callback)
	err != SBLESUCCESS && @error "Assigning callback failed"
	return nothing
end



### The following are internal and not sanitized for users

simpleble_adapter_is_bluetooth_enabled() = ccall((:simpleble_adapter_is_bluetooth_enabled, :simplecble), Bool, ())
simpleble_adapter_get_count() = ccall((:simpleble_adapter_get_count, :simplecble), Csize_t, ())
simpleble_adapter_underlying(handle) = ccall((:simpleble_adapter_underlying, :simplecble), Ptr{Cvoid}, (SBLEADAPTER, ), handle)
simpleble_adapter_power_on(handle) = ccall((:simpleble_adapter_power_on, :simplecble), SBLEERROR, (SBLEADAPTER, ), handle)
simpleble_adapter_power_off(handle) = ccall((:simpleble_adapter_power_off, :simplecble), SBLEERROR, (SBLEADAPTER, ), handle)
simpleble_adapter_is_powered(handle, ret) = ccall((:simpleble_adapter_is_powered, :simplecble), SBLEERROR, (SBLEADAPTER, Ptr{Bool}), handle, ret)
simpleble_adapter_scan_is_active(handle, ret) = ccall((:simpleble_adapter_scan_is_active, :simplecble), SBLEERROR, (SBLEADAPTER, Ptr{Bool}), handle, ret)
simpleble_adapter_scan_get_results_count(handle) = ccall((:simpleble_adapter_scan_get_results_count, :simplecble), Csize_t, (SBLEADAPTER, ), handle)
simpleble_adapter_scan_get_results_handle(handle, index) = ccall((:simpleble_adapter_scan_get_results_handle, :simplecble), SBLEPERIPHERAL, (SBLEADAPTER, Csize_t), handle, index) # Must release
simpleble_adapter_get_paired_peripherals_count(handle) = ccall((:simpleble_adapter_get_paired_peripherals_count, :simplecble), Csize_t, (SBLEADAPTER, ), handle)
simpleble_adapter_get_paired_peripherals_handle(handle, index) = ccall((:simpleble_adapter_get_paired_peripherals_handle, :simplecble), SBLEPERIPHERAL, (SBLEADAPTER, Csize_t), handle, index) # Must release
simpleble_adapter_get_connected_peripherals_count(handle) = ccall((:simpleble_adapter_get_connected_peripherals_count, :simplecble), Csize_t, (SBLEADAPTER, ), handle)
simpleble_adapter_get_connected_peripherals_handle(handle, index) = ccall((:simpleble_adapter_get_connected_peripherals_handle, :simplecble), SBLEPERIPHERAL, (SBLEADAPTER, Csize_t), handle, index) # Must release
