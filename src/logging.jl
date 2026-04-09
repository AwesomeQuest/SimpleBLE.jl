@enum SBLELOGLEVEL::Csize_t begin
	SIMPLEBLE_LOG_LEVEL_NONE = 0
	SIMPLEBLE_LOG_LEVEL_FATAL
	SIMPLEBLE_LOG_LEVEL_ERROR
	SIMPLEBLE_LOG_LEVEL_WARN
	SIMPLEBLE_LOG_LEVEL_INFO
	SIMPLEBLE_LOG_LEVEL_DEBUG
	SIMPLEBLE_LOG_LEVEL_VERBOSE
end

"""
	simpleble_logging_set_level(level::SimpleBLE.SBLELOGLEVEL)
Set the log level of simpleble
"""
simpleble_logging_set_level(level) = ccall((:simpleble_logging_set_level, simplecble), Cvoid, (SBLELOGLEVEL, ), level)

"""
	simpleble_logging_set_callback(callback)
	simpleble_logging_set_callback() do level::SBLELOGLEVEL,
			module::Cstring,
			file::Cstring,
			line::UInt32,
			function::Cstring,
			message::Cstring
		return nothing
	end
"""
function simpleble_logging_set_callback(callback)
	c_callback = @cfunction($callback, Cvoid, (SBLELOGLEVEL, Cstring, Cstring, UInt32, Cstring, Cstring))
	push!(active_callbacks, c_callback)
	ccall((:simpleble_logging_set_callback, simplecble), Cvoid, (Ptr{Cvoid}, ), c_callback)
end
