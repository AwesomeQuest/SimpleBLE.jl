module SimpleBLE


sbledir = joinpath(@__DIR__, "..", "simplecble", "shared", "bin", "simplecble.dll")


active_callbacks = Base.CFunction[]


@static if Sys.iswindows()
	global WinAdapter::Adapter = Adapter(C_NULL)
	atexit() do
		WinAdapter.ptr == C_NULL && return nothing
		@ccall sbledir.simpleble_adapter_set_callback_on_scan_start(WinAdapter::SBLEADAPTER, C_NULL::Ptr{Cvoid})::SBLEERROR
		@ccall sbledir.simpleble_adapter_set_callback_on_scan_stop(WinAdapter::SBLEADAPTER, C_NULL::Ptr{Cvoid})::SBLEERROR
		@ccall sbledir.simpleble_adapter_set_callback_on_scan_found(WinAdapter::SBLEADAPTER, C_NULL::Ptr{Cvoid})::SBLEERROR
		@ccall sbledir.simpleble_adapter_set_callback_on_scan_updated(WinAdapter::SBLEADAPTER, C_NULL::Ptr{Cvoid})::SBLEERROR

		actref = Ref{Bool}()
		err = @ccall sbledir.simpleble_adapter_scan_is_active(WinAdapter::SBLEADAPTER, actref::Ptr{Bool})::SBLEERROR
		while err == SBLEFAILURE
			@error "Failed to get scan active"
			err = @ccall sbledir.simpleble_adapter_scan_is_active(WinAdapter::SBLEADAPTER, actref::Ptr{Bool})::SBLEERROR
			sleep(0.2)
		end
		if actref[]
			err = @ccall sbledir.simpleble_adapter_scan_stop(WinAdapter::SBLEADAPTER)::SBLEERROR
			while err == SBLEFAILURE
				@error "Failed to stop scan"
				err = @ccall sbledir.simpleble_adapter_scan_stop(WinAdapter::SBLEADAPTER)::SBLEERROR
				sleep(0.2)
			end
		end
	end
end

free(x) = @ccall sbledir.simpleble_free(x::Ptr{Cvoid})::Cvoid


include("types.jl")
include("adapter.jl")
include("peripheral.jl")
include("logging.jl")
include("utils.jl")

simpleble_get_operating_system() = @ccall sbledir.simpleble_get_operating_system()::SBLEOS

function simpleble_get_version()
	c_str = @ccall sbledir.simpleble_get_version()::Cstring
	return unsafe_string(c_str)
end

end # module SimpleBLE
