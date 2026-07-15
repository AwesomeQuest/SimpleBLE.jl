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
	peri = nothing
	try
		peri = take!(perich)
	finally
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
	end

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

function _props(c::SBLECHARACTERISTIC)
    props = String[]
    c.can_read          && push!(props, "read")
    c.can_write_request && push!(props, "write")
    c.can_write_command && push!(props, "write_no_rsp")
    c.can_notify        && push!(props, "notify")
    c.can_indicate      && push!(props, "indicate")
    isempty(props) && push!(props, "none")
    return join(props, ", ")
end

function _hexdata(data::NTuple{27, UInt8}, len::Csize_t)
    len == 0 && return ""
    parts = string.(data[1:len]; base=16, pad=2)
    return " [" * join(parts, " ") * "]"
end


"""
    print_services([io=stdout,] services)
    print_services([io=stdout,] peripheral)

Pretty-print a device's service tree with indentation.
If given a `Peripheral`, fetches services first.
"""
function print_services(io::IO, services::Vector{SBLESERVICE})
    for (i, svc) in enumerate(services)
        i > 1 && println(io)
        sdata = _hexdata(svc.data, svc.data_length)
        println(io, "Service: ", svc.uuid, sdata)
        for k in 1:svc.characteristic_count
            ch = svc.characteristics[k]
            println(io, "  Characteristic: ", ch.uuid, " [", _props(ch), "]")
            for j in 1:ch.descriptor_count
                d = ch.descriptors[j]
                println(io, "    Descriptor: ", d.uuid)
            end
        end
    end
end

print_services(services::Vector{SBLESERVICE}) = print_services(stdout, services)

function print_services(io::IO, p::Peripheral)
    print_services(io, services(p))
end

print_services(p::Peripheral) = print_services(stdout, p)
