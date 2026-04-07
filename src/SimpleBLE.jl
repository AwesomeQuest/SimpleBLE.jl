module SimpleBLE

using SimpleBLE_jll


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

global adapters = Adapter[]
atexit() do
	for a in adapters
		ccall((:simpleble_adapter_set_callback_on_scan_start, :simplecble), SBLEERROR, (SBLEADAPTER, Ptr{Cvoid}), a, C_NULL)
		ccall((:simpleble_adapter_set_callback_on_scan_stop, :simplecble), SBLEERROR, (SBLEADAPTER, Ptr{Cvoid}), a, C_NULL)
		ccall((:simpleble_adapter_set_callback_on_scan_found, :simplecble), SBLEERROR, (SBLEADAPTER, Ptr{Cvoid}), a, C_NULL)
		ccall((:simpleble_adapter_set_callback_on_scan_updated, :simplecble), SBLEERROR, (SBLEADAPTER, Ptr{Cvoid}), a, C_NULL)

		actref = Ref{Bool}()
		err = ccall((:simpleble_adapter_scan_is_active, :simplecble), SBLEERROR, (SBLEADAPTER, Ptr{Bool}), WinAdapter, actref)
		err == SBLEFAILURE && @error "Failed to get scan acitve"
		if actref[]
			err = ccall((:simpleble_adapter_scan_stop, :simplecble), SBLEERROR, (SBLEADAPTER, ), WinAdapter)
			err == SBLEFAILURE && @error "Failed to stop scan"
		end
	end
end


end # module SimpleBLE
