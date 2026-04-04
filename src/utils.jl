"""
Convenience function for finding a peripheral.
matchfunc must take one string argument and return a bool
"""
function find_peripheral(matchfunc, adapter)
	adapterid = identifier(adapter)
	perich = Channel{Peripheral}(Inf)
	set_callback_on_scan_start(x->@info("Scan starting on $adapterid"), adapter)
	set_callback_on_scan_stop(x->@info("Scanning stopping on $adapterid"), adapter)
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

	return peri
end

"""
Convenience function for automatically disconnecting from a 
peripheral once you're done with it
"""
function connect(func, peripheral::Peripheral)
	connect(peripheral)
	try
		func()
	catch e
		throw(e)
	finally
		disconnect(peripheral)
	end
end