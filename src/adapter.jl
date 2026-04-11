export is_bluetooth_enabled,
	adapters_get_count,
	get_adapter,
	get_adapters,
	identifier,
	address,
	power_on,
	power_off,
	is_powered,
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


### The following are public function intended for users

"Check if system bluetooth is enabled"
const is_bluetooth_enabled() = ccall(
	(:simpleble_adapter_is_bluetooth_enabled, simplecble),
	Bool,
	()
)

"Get number of adapters in system"
const adapters_get_count() = ccall(
	(:simpleble_adapter_get_count, simplecble),
	Csize_t,
	()
)

"""
	get_adapter(i)
Acquire a handle to an adapter. `i` is an index starting at 0.
You can check the number of adapters with [`adapters_get_count`](@ref).
"""
function get_adapter(i)
	adapter = ccall(
		(:simpleble_adapter_get_handle, simplecble),
		Ptr{Cvoid},
		(Csize_t, ),
		i
	)
	A = Adapter(adapter)
	push!(adapters, A)
	return A
end

"Get a Vector of adapters"
function get_adapters()
	adapters = Adapter[]
	count = adapters_get_count()
	count == 0 && return adapters
	for i in 0:adapters_get_count()-1
		A = get_adapter(i)
		push!(adapters, A)
	end
	return adapters
end

"""
	identifier(adapter)
Get the name of an `adapter`.

See also [`address(::Adapter)`](@ref)
"""
function identifier(adapter::Adapter)
	cstr = ccall(
		(:simpleble_adapter_identifier, simplecble),
		Cstring,
		(SBLEADAPTER, ),
		adapter
	)
	return finalizer(unsafe_string(cstr)) do x
		# @async @warn "$(time_ns()): Freeing string with value $x"
		free(pointer(cstr))
	end
end

"""
	address(adapter)
Get the address of an `adapter`.

See also [`identifier(::Adapter)`](@ref)
"""
function address(adapter::Adapter)
	cstr = ccall(
		(:simpleble_adapter_address, simplecble),
		Cstring,
		(SBLEADAPTER, ),
		adapter
	)
	return finalizer(unsafe_string(cstr)) do x
		# @async @warn "$(time_ns()): Freeing string with value $x"
		free(pointer(cstr))
	end
end

"""
	power_on(adapter)
Power on an `adapter`

See also [`power_off`](@ref), [`is_powered`](@ref)
"""
function power_on(adapter::Adapter)
	err = ccall(
		(:simpleble_adapter_power_on, simplecble),
		SBLEERROR,
		(SBLEADAPTER, ),
		adapter
	)
	return err == SBLESUCCESS
end

"""
	power_off(adapter)
Power on an `adapter`

See also [`power_on`](@ref), [`is_powered`](@ref)
"""
function power_off(adapter::Adapter)
	err = ccall(
		(:simpleble_adapter_power_off, simplecble),
		SBLEERROR,
		(SBLEADAPTER, ),
		adapter
	)
	return err == SBLESUCCESS
end

"""
	is_powered(adapter)
Check if `adapter` is powered

See also [`power_on`](@ref), [`power_off`](@ref)
"""
function is_powered(adapter::Adapter)
	ret = Ref{Bool}()
	err = ccall(
		(:simpleble_adapter_is_powered, simplecble),
		SBLEERROR, (SBLEADAPTER, Ptr{Bool}),
		adapter, ret
	)
	if err == SBLEFAILURE
		@error "Failed to check adapter power"
		return nothing
	end
	return ret[]
end

"""
	set_callback_on_power_on(callback, adapter)
	set_callback_on_power_on(adapter) do
		# Stuff
	end
Set a callback that is called when an adapter is powered on.
"""
function set_callback_on_power_on(callback, adapter::Adapter)
	function adjcallback(adapter, userdata)
		wait(errormonitor(@async callback()); throw=false)
		return nothing
	end
	c_callback = @cfunction($adjcallback, Cvoid, (SBLEADAPTER, Ptr{Cvoid}))
	push!(active_callbacks, c_callback)
	err = ccall(
		(:simpleble_adapter_set_callback_on_power_on, simplecble),
		SBLEERROR,
		(SBLEADAPTER, Ptr{Cvoid}, Ptr{Cvoid}),
		adapter, c_callback, C_NULL
	)
	err != SBLESUCCESS && @error "Assigning callback failed"
	return nothing
end

"""
	set_callback_on_power_off(callback, adapter)
	set_callback_on_power_off(adapter) do
		# Stuff
	end
Set a callback that is called when an adapter is powered off.
"""
function set_callback_on_power_off(callback, adapter::Adapter)
	function adjcallback(adapter, userdata)
		wait(errormonitor(@async callback()); throw=false)
		return nothing
	end
	c_callback = @cfunction($adjcallback, Cvoid, (SBLEADAPTER, Ptr{Cvoid}))
	push!(active_callbacks, c_callback)
	err = ccall(
		(:simpleble_adapter_set_callback_on_power_off, simplecble),
		SBLEERROR,
		(SBLEADAPTER, Ptr{Cvoid}, Ptr{Cvoid}),
		adapter, c_callback, C_NULL
	)
	err != SBLESUCCESS && @error "Assigning callback failed"
	return nothing
end

"""
	scan_start(adapter)
Start scanning for peripherals. Results can be acquired with `scan_get_results`.
Or check each peripheral found or updated inside a callback set
by `set_callback_on_scan_found`

See also [`scan_stop`](@ref), [`scan_for`](@ref)
"""
function scan_start(adapter::Adapter)
	err = ccall(
		(:simpleble_adapter_scan_start, simplecble),
		SBLEERROR,
		(SBLEADAPTER, ),
		adapter
	)
	err == SBLEFAILURE && @error "Failed to start scan"
	return nothing
end

"	scan_stop(adapter)\nStop a scan"
function scan_stop(adapter::Adapter)
	err = ccall(
		(:simpleble_adapter_scan_stop, simplecble),
		SBLEERROR,
		(SBLEADAPTER, ),
		adapter
	)
	err == SBLEFAILURE && @error "Failed to stop scan"
	return nothing
end

"	scan_is_active(adapter)\nCheck if adapter is scanning"
function scan_is_active(adapter::Adapter)
	ret = Ref{Bool}()
	err = ccall(
		(:simpleble_adapter_scan_is_active, simplecble),
		SBLEERROR,
		(SBLEADAPTER, Ptr{Bool}),
		adapter, ret
	)
	if err == SBLEFAILURE
		@error "Failed to check scan active"
		return nothing
	end
	return ret[]
end

"""
	scan_for(adapter, timeout_ms)
Scan for a specified number of ms. Results can be acquired with `scan_get_results`.
Or check each peripheral found or updated inside a callback set
by `set_callback_on_scan_found`

See also [`scan_start`](@ref), [`scan_stop`](@ref)
"""
function scan_for(adapter::Adapter, timeout_ms)
	err = ccall(
		(:simpleble_adapter_scan_for, simplecble),
		SBLEERROR,
		(SBLEADAPTER, Cint),
		adapter, timeout_ms
	)
	err == SBLEFAILURE && @error "Failed to scan"
	return nothing
end

"""
	scan_get_results(adapter)
Get the results of a scan.

See also [`scan_start`](@ref), [`scan_stop`](@ref), [`scan_for`](@ref)
"""
function scan_get_results(adapter::Adapter)
	peris = Peripheral[]
	count = ccall(
		(:simpleble_adapter_scan_get_results_count, simplecble),
		Csize_t,
		(SBLEADAPTER, ),
		adapter
	)
	count == 0 && return peris
	for i in 0:count-1
		c_p = ccall(
			(:simpleble_adapter_scan_get_results_handle, simplecble),
			SBLEPERIPHERAL,
			(SBLEADAPTER, Csize_t),
			adapter, i
		)
		P = Peripheral(c_p)
		push!(peris, P)
	end
	return peris
end

"	get_paired_peripherals(adapter)\nGet list of peripherals paired with `adapter`"
function get_paired_peripherals(adapter::Adapter)
	peris = Peripheral[]
	count = ccall(
		(:simpleble_adapter_get_paired_peripherals_count, simplecble),
		Csize_t,
		(SBLEADAPTER, ),
		adapter
	)
	# count is unsigned so count-1 == typemax(Csize_t) :)
	count == 0 && return peris
	for i in 0:count-1
		c_p = ccall(
			(:simpleble_adapter_get_paired_peripherals_handle, simplecble),
			SBLEPERIPHERAL,
			(SBLEADAPTER, Csize_t),
			adapter, i
		)
		P = Peripheral(c_p)
		push!(peris, P)
	end
	return peris
end

"""
	get_connected_peripherals(adapter)
Get a vector of connected peripherals.
"""
function get_connected_peripherals(adapter::Adapter)
	peris = Peripheral[]
	count = ccall(
		(:simpleble_adapter_get_connected_peripherals_count, simplecble),
		Csize_t,
		(SBLEADAPTER, ),
		adapter
	)
	count == 0 && return peris
	for i in 0:count-1
		c_p = ccall(
			(:simpleble_adapter_get_connected_peripherals_handle, simplecble),
			SBLEPERIPHERAL,
			(SBLEADAPTER, Csize_t),
			adapter, i
		)
		P = Peripheral(c_p)
		push!(peris, P)
	end
	return peris
end

"""
	set_callback_on_scan_start(callback, adapter)
	set_callback_on_scan_start(adapter) do
		# Stuff
	end
Set a callback that is called when an adapter starts scanning.

See also [`scan_start`](@ref), [`scan_stop`](@ref), [`scan_for`](@ref)
"""
function set_callback_on_scan_start(callback, adapter::Adapter)
	function adjcallback(adapter, userdata)
		wait(errormonitor(@async callback()); throw=false)
		return nothing
	end
	c_callback = @cfunction($adjcallback, Cvoid, (SBLEADAPTER, Ptr{Cvoid}))
	push!(active_callbacks, c_callback)
	err = ccall(
		(:simpleble_adapter_set_callback_on_scan_start, simplecble),
		SBLEERROR,
		(SBLEADAPTER, Ptr{Cvoid}, Ptr{Cvoid}),
		adapter, c_callback, C_NULL
	)
	err != SBLESUCCESS && @error "Assigning callback failed"
	return nothing
end

"""
	set_callback_on_scan_stop(callback, adapter)
	set_callback_on_scan_stop(adapter) do
		# Stuff
	end
Set a callback that is called when an adapter stops scanning.

See also [`scan_start`](@ref), [`scan_stop`](@ref), [`scan_for`](@ref)
"""
function set_callback_on_scan_stop(callback, adapter::Adapter)
	function adjcallback(adapter, userdata)
		wait(errormonitor(@async callback()); throw=false)
		return nothing
	end
	c_callback = @cfunction($adjcallback, Cvoid, (SBLEADAPTER, Ptr{Cvoid}))
	push!(active_callbacks, c_callback)
	err = ccall(
		(:simpleble_adapter_set_callback_on_scan_stop, simplecble),
		SBLEERROR, (SBLEADAPTER, Ptr{Cvoid}, Ptr{Cvoid}),
		adapter, c_callback, C_NULL
	)
	err != SBLESUCCESS && @error "Assigning callback failed"
	return nothing
end

"""
	set_callback_on_scan_found(callback, adapter)
	set_callback_on_scan_found(adapter) do peripheral
		# Stuff
	end
Set a callback that is called when an adapter finds a peripheral.

See also [`scan_start`](@ref), [`scan_stop`](@ref), [`scan_for`](@ref)
"""
function set_callback_on_scan_found(callback, adapter::Adapter)
	function adjcallback(adapter, peripheral, userdata)
		P = Peripheral(peripheral)
		wait(errormonitor(@async callback(P)); throw=false)
		return nothing
	end
	c_callback = @cfunction($adjcallback, Cvoid, (SBLEADAPTER, SBLEPERIPHERAL, Ptr{Cvoid}))
	push!(active_callbacks, c_callback)
	err = ccall(
		(:simpleble_adapter_set_callback_on_scan_found, simplecble),
		SBLEERROR,
		(SBLEADAPTER, Ptr{Cvoid}, Ptr{Cvoid}),
		adapter, c_callback, C_NULL
	)
	err != SBLESUCCESS && @error "Assigning callback failed"
	return nothing
end

"""
	set_callback_on_scan_updated(callback, adapter)
	set_callback_on_scan_updated(adapter) do peripheral
		# Stuff
	end
Set a callback that is called when an adapter updates a peripheral.

See also [`scan_start`](@ref), [`scan_stop`](@ref), [`scan_for`](@ref)
"""
function set_callback_on_scan_updated(callback, adapter::Adapter)
	function adjcallback(adapter, peripheral, userdata)
		P = Peripheral(peripheral)
		wait(errormonitor(@async callback(P)); throw=false)
		return nothing
	end
	c_callback = @cfunction($adjcallback, Cvoid, (SBLEADAPTER, SBLEPERIPHERAL, Ptr{Cvoid}))
	push!(active_callbacks, c_callback)
	err = ccall(
		(:simpleble_adapter_set_callback_on_scan_updated, simplecble),
		SBLEERROR,
		(SBLEADAPTER, Ptr{Cvoid}),
		adapter, c_callback
	)
	err != SBLESUCCESS && @error "Assigning callback failed"
	return nothing
end


### The following are internal and not sanitized for users

"`simpleble_adapter_underlying(handle)`"
simpleble_adapter_underlying(handle) = ccall(
	(:simpleble_adapter_underlying, simplecble),
	Ptr{Cvoid},
	(SBLEADAPTER, ),
	handle
)