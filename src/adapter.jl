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
	adapter = @ccall sbledir.simpleble_adapter_get_handle(i::Csize_t)::Ptr{Cvoid}
	global WinAdapter = Adapter(adapter)
	return WinAdapter
end

function identifier(adapter::Adapter)
	cstr = @ccall sbledir.simpleble_adapter_identifier(adapter::SBLEADAPTER)::Cstring
	return finalizer(unsafe_string(cstr)) do x
		@async @warn "$(time_ns()): Freeing string with value $x"
		free(pointer(cstr))
	end
end

function address(peripheral::Adapter)
	cstr = @ccall sbledir.simpleble_adapter_address(peripheral::SBLEADAPTER)::Cstring
	return finalizer(unsafe_string(cstr)) do x
		@async @warn "$(time_ns()): Freeing string with value $x"
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
	err = @ccall sbledir.simpleble_adapter_set_callback_on_power_on(adapter::SBLEADAPTER, c_callback::Ptr{Cvoid}, C_NULL::Ptr{Cvoid})::SBLEERROR
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
	err = @ccall sbledir.simpleble_adapter_set_callback_on_power_off(adapter::SBLEADAPTER, c_callback::Ptr{Cvoid}, C_NULL::Ptr{Cvoid})::SBLEERROR
	err != SBLESUCCESS && @error "Assigning callback failed"
	return nothing
end

function scan_start(adapter::Adapter)
	err = @ccall sbledir.simpleble_adapter_scan_start(adapter::SBLEADAPTER)::SBLEERROR
	err == SBLEFAILURE && @error "Failed to start scan"
	return nothing
end

function scan_stop(adapter::Adapter)
	err = @ccall sbledir.simpleble_adapter_scan_stop(adapter::SBLEADAPTER)::SBLEERROR
	err == SBLEFAILURE && @error "Failed to stop scan"
	return nothing
end

function scan_for(adapter::Adapter, timeout_ms)
	err = @ccall sbledir.simpleble_adapter_scan_for(adapter::SBLEADAPTER, timeout_ms::Cint)::SBLEERROR
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
	err = @ccall sbledir.simpleble_adapter_set_callback_on_scan_start(adapter::SBLEADAPTER, c_callback::Ptr{Cvoid}, C_NULL::Ptr{Cvoid})::SBLEERROR
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
	err = @ccall sbledir.simpleble_adapter_set_callback_on_scan_stop(adapter::SBLEADAPTER, c_callback::Ptr{Cvoid}, C_NULL::Ptr{Cvoid})::SBLEERROR
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
	err = @ccall sbledir.simpleble_adapter_set_callback_on_scan_found(adapter::SBLEADAPTER, c_callback::Ptr{Cvoid}, C_NULL::Ptr{Cvoid})::SBLEERROR
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
	err = @ccall sbledir.simpleble_adapter_set_callback_on_scan_updated(adapter::SBLEADAPTER, c_callback::Ptr{Cvoid})::SBLEERROR
	err != SBLESUCCESS && @error "Assigning callback failed"
	return nothing
end



### The following are internal and not sanitized for users

simpleble_adapter_is_bluetooth_enabled() = @ccall sbledir.simpleble_adapter_is_bluetooth_enabled()::Bool
simpleble_adapter_get_count() = @ccall sbledir.simpleble_adapter_get_count()::Csize_t
simpleble_adapter_underlying(handle) = @ccall sbledir.simpleble_adapter_underlying(handle::SBLEADAPTER)::Ptr{Cvoid}
simpleble_adapter_power_on(handle) = @ccall sbledir.simpleble_adapter_power_on(handle::SBLEADAPTER)::SBLEERROR
simpleble_adapter_power_off(handle) = @ccall sbledir.simpleble_adapter_power_off(handle::SBLEADAPTER)::SBLEERROR
simpleble_adapter_is_powered(handle, ret) = @ccall sbledir.simpleble_adapter_is_powered(handle::SBLEADAPTER, ret::Ptr{Bool})::SBLEERROR
simpleble_adapter_scan_is_active(handle, ret) = @ccall sbledir.simpleble_adapter_scan_is_active(handle::SBLEADAPTER, ret::Ptr{Bool})::SBLEERROR
simpleble_adapter_scan_get_results_count(handle) = @ccall sbledir.simpleble_adapter_scan_get_results_count(handle::SBLEADAPTER)::Csize_t
simpleble_adapter_scan_get_results_handle(handle, index) = @ccall sbledir.simpleble_adapter_scan_get_results_handle(handle::SBLEADAPTER, index::Csize_t)::SBLEPERIPHERAL # Must release
simpleble_adapter_get_paired_peripherals_count(handle) = @ccall sbledir.simpleble_adapter_get_paired_peripherals_count(handle::SBLEADAPTER)::Csize_t
simpleble_adapter_get_paired_peripherals_handle(handle, index) = @ccall sbledir.simpleble_adapter_get_paired_peripherals_handle(handle::SBLEADAPTER, index::Csize_t)::SBLEPERIPHERAL # Must release
simpleble_adapter_get_connected_peripherals_count(handle) = @ccall sbledir.simpleble_adapter_get_connected_peripherals_count(handle::SBLEADAPTER)::Csize_t
simpleble_adapter_get_connected_peripherals_handle(handle, index) = @ccall sbledir.simpleble_adapter_get_connected_peripherals_handle(handle::SBLEADAPTER, index::Csize_t)::SBLEPERIPHERAL # Must release
