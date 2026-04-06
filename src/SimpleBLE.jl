module SimpleBLE


@static if Sys.iswindows()
	bindir = joinpath(@__DIR__, "..", "simplecble","shared","bin")
	dll = joinpath(bindir, "simpleble.dll")
	cdll = joinpath(bindir, "simplecble.dll")
	tdir = tempname()
	mkdir(tdir)
	@show tdir
	@show isdir(tdir)
	cp(dll, joinpath(tdir, "simpleble.dll"))
	cp(cdll, joinpath(tdir, "simplecble.dll"))
	hdl = Libc.Libdl.dlopen(joinpath(tdir, "simplecble.dll"))
	@show isfile(joinpath(tdir, "simpleble.dll"))

	atexit() do 
		Libc.Libdl.dlclose(hdl)
		rm(joinpath(tdir, "simpleble.dll"))
		rm(joinpath(tdir, "simplecble.dll"))
	end
else
	using SimpleBLE_jll
end


active_callbacks = Base.CFunction[]



free(x) = ccall((:simpleble_free, :simplecble), Cvoid, (Ptr{Cvoid}, ), x)


include("types.jl")
include("adapter.jl")
include("peripheral.jl")
include("logging.jl")
include("utils.jl")

simpleble_get_operating_system() = ccall((:simpleble_get_operating_system, :simplecble), SBLEOS, ())

function simpleble_get_version()
	c_str = ccall((:simpleble_get_version, :simplecble), Cstring, ())
	return unsafe_string(c_str)
end

@static if Sys.iswindows()
	global WinAdapter = Adapter(C_NULL)
	atexit() do
		@info "Exiting and cleaning up"
		WinAdapter.ptr == C_NULL && return nothing
		@info Clearing callbacks
		ccall((:simpleble_adapter_set_callback_on_scan_start, :simplecble), SBLEERROR, (SBLEADAPTER, Ptr{Cvoid}), WinAdapter, C_NULL)
		ccall((:simpleble_adapter_set_callback_on_scan_stop, :simplecble), SBLEERROR, (SBLEADAPTER, Ptr{Cvoid}), WinAdapter, C_NULL)
		ccall((:simpleble_adapter_set_callback_on_scan_found, :simplecble), SBLEERROR, (SBLEADAPTER, Ptr{Cvoid}), WinAdapter, C_NULL)
		ccall((:simpleble_adapter_set_callback_on_scan_updated, :simplecble), SBLEERROR, (SBLEADAPTER, Ptr{Cvoid}), WinAdapter, C_NULL)

		@info "Stopping potential scan"
		actref = Ref{Bool}()
		err = ccall((:simpleble_adapter_scan_is_active, :simplecble), SBLEERROR, (SBLEADAPTER, Ptr{Bool}), WinAdapter, actref)
		while err == SBLEFAILURE
			@error "Failed to get scan active"
			err = ccall((:simpleble_adapter_scan_is_active, :simplecble), SBLEERROR, (SBLEADAPTER, Ptr{Bool}), WinAdapter, actref)
			sleep(0.2)
		end
		if actref[]
			err = ccall((:simpleble_adapter_scan_stop, :simplecble), SBLEERROR, (SBLEADAPTER, ), WinAdapter)
			while err == SBLEFAILURE
				@error "Failed to stop scan"
				err = ccall((:simpleble_adapter_scan_stop, :simplecble), SBLEERROR, (SBLEADAPTER, ), WinAdapter)
				sleep(0.2)
			end
		end
	end
end


end # module SimpleBLE
