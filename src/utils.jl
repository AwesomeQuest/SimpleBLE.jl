export find_peripheral,
	connect


"""
	find_peripheral(matchfunc, adapter)
	find_peripheral(adapter) do identifier::String
		# Stuff
		return output::Bool
	end
Convenience function for finding a peripheral.
`identifier` is the name of the peripheral, it can be an empty string.
"""
function find_peripheral(matchfunc, adapter)
	adapterid = identifier(adapter)
	perich = Channel{Peripheral}(Inf)
	set_callback_on_scan_start(()->@info("Scan starting on $adapterid"), adapter)
	set_callback_on_scan_stop(()->@info("Scanning stopping on $adapterid"), adapter)
	set_callback_on_scan_found(adapter) do peri
		id = identifier(peri)
		adr = address(peri)
		@info "Peripheral found $id [$adr]"
		matchfunc(id) && put!(perich, peri)
	end
	set_callback_on_scan_updated(adapter) do peri
		id = identifier(peri)
		adr = address(peri)
		@info "Peripheral updated $id [$adr]"
		matchfunc(id) && put!(perich, peri)
	end

	scan_start(adapter)
	@info "Waiting for peripheral"
	peri = take!(perich)
	scan_stop(adapter)
	sleep(1)
	close(perich)

	# Clean up
	ccall(
		(:simpleble_adapter_set_callback_on_scan_start, simplecble),
		SBLEERROR,
		(SBLEADAPTER, Ptr{Cvoid}),
		adapter, C_NULL
	)
	ccall(
		(:simpleble_adapter_set_callback_on_scan_stop, simplecble),
		SBLEERROR,
		(SBLEADAPTER, Ptr{Cvoid}),
		adapter, C_NULL
	)
	ccall(
		(:simpleble_adapter_set_callback_on_scan_found, simplecble),
		SBLEERROR,
		(SBLEADAPTER, Ptr{Cvoid}),
		adapter, C_NULL
	)
	ccall(
		(:simpleble_adapter_set_callback_on_scan_updated, simplecble),
		SBLEERROR,
		(SBLEADAPTER, Ptr{Cvoid}),
		adapter, C_NULL
	)

	return peri
end

"""
	connect(callback, peripheral)
	connect(peripheral) do
		# Stuff
	end
Convenience function for automatically disconnecting from a
peripheral once you're done with it
"""
function connect(func, peripheral::Peripheral)
	connect(peripheral) || return false
	try
		func()
	catch e
		throw(e)
	finally
		disconnect(peripheral)
	end
	return true
end
