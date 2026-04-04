

### The following are internal types not inteded for users

const SIMPLEBLE_UUID_STR_LEN =37  # 36 characters + null terminator
const SIMPLEBLE_CHARACTERISTIC_MAX_COUNT =16
const SIMPLEBLE_DESCRIPTOR_MAX_COUNT =16



@enum SBLEERROR::Csize_t begin 
	SBLESUCCESS =0
	SBLEFAILURE =1
end;

struct SBLEUUID
	value::NTuple{SIMPLEBLE_UUID_STR_LEN, Cchar};
	SBLEUUID(x) = new(x)
	function SBLEUUID(s::T) where T <: AbstractString
		s = codeunits(s)
		out = zeros(Cchar, SIMPLEBLE_UUID_STR_LEN)
		out[1:min(length(s), SIMPLEBLE_UUID_STR_LEN)] .= s
		return new(NTuple{SIMPLEBLE_UUID_STR_LEN, Cchar}(out))
	end
end

struct SBLEDESCRIPTOR
	uuid::SBLEUUID
end

struct SBLECHARACTERISTIC
	uuid::SBLEUUID
	can_read::Bool
	can_write_request::Bool
	can_write_command::Bool
	can_notify::Bool
	can_indicate::Bool
	descriptor_count::Csize_t
	descriptors::NTuple{SIMPLEBLE_DESCRIPTOR_MAX_COUNT, SBLEDESCRIPTOR}
end

struct SBLESERVICE
	uuid::SBLEUUID
	data_length::Csize_t
	data::NTuple{27, UInt8}
	characteristic_count::Csize_t
	characteristics::NTuple{SIMPLEBLE_CHARACTERISTIC_MAX_COUNT, SBLECHARACTERISTIC}
end

struct SBLEMANUFACTURERDATA
	manufacturer_id::UInt16
	data_length::Csize_t
	data::NTuple{27, UInt8}
end


const SBLEADAPTER = Ptr{Cvoid}
const SBLEPERIPHERAL = Ptr{Cvoid}


@enum SBLEOS::Csize_t begin
	SIMPLEBLE_OS_WINDOWS = 0
	SIMPLEBLE_OS_MACOS = 1
	SIMPLEBLE_OS_LINUX = 2
end;

@enum SBLEADDRESSTYPE::Csize_t begin
	SIMPLEBLE_ADDRESS_TYPE_PUBLIC = 0
	SIMPLEBLE_ADDRESS_TYPE_RANDOM = 1
	SIMPLEBLE_ADDRESS_TYPE_UNSPECIFIED = 2
end


### The following are types used by julia

# Only ever create a adapter alongside a ccall that returns a handle
mutable struct Adapter
	ptr::SBLEADAPTER
	function Adapter(x)
		return finalizer(new(x)) do y
			# @async @warn "$(time_ns()): Finalizing Adapter $(y.ptr)"
			@ccall sbledir().simpleble_adapter_release_handle(y.ptr::SBLEADAPTER)::Cvoid
		end
	end
end
Base.cconvert(::Type{SBLEADAPTER}, x::Adapter) = x.ptr

# Only ever create a peripheral alongside a ccall that returns a handle
mutable struct Peripheral
	ptr::SBLEPERIPHERAL
	subscriptions::Set{Tuple{SBLEUUID,SBLEUUID}}
	function Peripheral(x)
		return finalizer(new(x, Set{Tuple{SBLEUUID,SBLEUUID}}())) do y
			# @async @warn "$(time_ns()): Finalizing Peripheral $(y.ptr)"
			@ccall sbledir().simpleble_peripheral_set_callback_on_connected(y.ptr::SBLEPERIPHERAL, C_NULL::Ptr{Cvoid})::SBLEERROR
			@ccall sbledir().simpleble_peripheral_set_callback_on_disconnected(y.ptr::SBLEPERIPHERAL, C_NULL::Ptr{Cvoid})::SBLEERROR

			for (s,c) in y.subscriptions
				@ccall sbledir().simpleble_peripheral_unsubscribe(y.ptr::SBLEPERIPHERAL, s::SBLEUUID, c::SBLEUUID)::SBLEERROR
			end
			empty!(y.subscriptions)
			@ccall sbledir().simpleble_peripheral_release_handle(y.ptr::SBLEPERIPHERAL)::Cvoid
		end
	end
end
Base.cconvert(::Type{SBLEPERIPHERAL}, x::Peripheral) = x.ptr
