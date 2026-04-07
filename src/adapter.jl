export is_bluetooth_enabled,
	adapter_get_count,
	get_adapter,
	identifier,
	address,
	set_callback_on_power_on,
	set_callback_on_power_off,
	scan_start,
	scan_stop,
	scan_is_active,
	scan_for,
	scan_get_results,
	get_paired_peripherals,
	get_connected_peripherals,
	set_callback_on_scan_start,
	set_callback_on_scan_stop,
	set_callback_on_scan_found,
	set_callback_on_scan_updated


### The following are public function inteded for users

const is_bluetooth_enabled() = ccall((:simpleble_adapter_is_bluetooth_enabled, :simplecble), Bool, ())

const adapter_get_count() = ccall((:simpleble_adapter_get_count, :simplecble), Csize_t, ())

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


function power_on(adapter::Adapter)
	err = ccall((:simpleble_adapter_power_on, :simplecble), SBLEERROR, (SBLEADAPTER, ), handle)
	return err == SBLESUCCESS
end

function power_off(adapter::Adapter)
	err = ccall((:simpleble_adapter_power_off, :simplecble), SBLEERROR, (SBLEADAPTER, ), handle)
	return err == SBLESUCCESS
end

function is_powered(adapter::Adapter)
	ret = Ref{Bool}()
	err = ccall((:simpleble_adapter_is_powered, :simplecble), SBLEERROR, (SBLEADAPTER, Ptr{Bool}), adapter, ret)
	if err == SBLEFAILURE
		@error "Failed to check adapter power"
		return nothing
	end
	return ret[]
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

function scan_is_active(adapter::Adapter)
	ret = Ref{Bool}()
	err = ccall((:simpleble_adapter_scan_is_active, :simplecble), SBLEERROR, (SBLEADAPTER, Ptr{Bool}), adapter, ret)
	if err == SBLEFAILURE
		@error "Failed to check scan active"
		return nothing
	end
	return ret[]
end

function scan_for(adapter::Adapter, timeout_ms)
	err = ccall((:simpleble_adapter_scan_for, :simplecble), SBLEERROR, (SBLEADAPTER, Cint), adapter, timeout_ms)
	err == SBLEFAILURE && @error "Failed to scan"
	return nothing
end

function scan_get_results(adapter::Adapter)
	peris = Peripheral[]
	count = ccall((:simpleble_adapter_scan_get_results_count, :simplecble), Csize_t, (SBLEADAPTER, ), adapter)
	for i in 0:count-1
		c_p = ccall((:simpleble_adapter_scan_get_results_handle, :simplecble), SBLEPERIPHERAL, (SBLEADAPTER, Csize_t), adapter, i)
		P = Peripheral(c_p)
		push!(peris, P)
	end
	return peris
end

function get_paired_peripherals(adapter::Adapter)
	peris = Peripheral[]
	count = ccall((:simpleble_adapter_get_paired_peripherals_count, :simplecble), Csize_t, (SBLEADAPTER, ), adapter)
	for i in 0:count-1
		c_p = ccall((:simpleble_adapter_get_paired_peripherals_handle, :simplecble), SBLEPERIPHERAL, (SBLEADAPTER, Csize_t), adapter, i)
		P = Peripheral(c_p)
		push!(peris, P)
	end
	return peris
end

function get_connected_peripherals(adapter::Adapter)
	peris = Peripheral[]
	count = ccall((:simpleble_adapter_get_connected_peripherals_count, :simplecble), Csize_t, (SBLEADAPTER, ), adapter)
	for i in 0:count-1
		c_p = ccall((:simpleble_adapter_get_connected_peripherals_handle, :simplecble), SBLEPERIPHERAL, (SBLEADAPTER, Csize_t), adapter, i)
		P = Peripheral(c_p)
		push!(peris, P)
	end
	return peris
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

simpleble_adapter_underlying(handle) = ccall((:simpleble_adapter_underlying, :simplecble), Ptr{Cvoid}, (SBLEADAPTER, ), handle)