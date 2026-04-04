@enum SBLELOGLEVEL::Csize_t begin
	SIMPLEBLE_LOG_LEVEL_NONE = 0
	SIMPLEBLE_LOG_LEVEL_FATAL
	SIMPLEBLE_LOG_LEVEL_ERROR
	SIMPLEBLE_LOG_LEVEL_WARN
	SIMPLEBLE_LOG_LEVEL_INFO
	SIMPLEBLE_LOG_LEVEL_DEBUG
	SIMPLEBLE_LOG_LEVEL_VERBOSE
end

simpleble_logging_set_level(level) = @ccall sbledir.simpleble_logging_set_level(level::SBLELOGLEVEL)::Cvoid

function simpleble_logging_set_callback(callback)
	c_callback = @cfunction($callback, Cvoid, (SBLELOGLEVEL, Cstring, Cstring, UInt32, Cstring, Cstring))
	push!(active_callbacks, c_callback)
	@ccall sbledir.simpleble_logging_set_callback(c_callback::Ptr{Cvoid})
end