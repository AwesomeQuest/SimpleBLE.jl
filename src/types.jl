export Adapter,
	Peripheral,
	SBLEUUID

import Base

### The following are internal types not intended for users

const SIMPLEBLE_UUID_STR_LEN =37  # 36 characters + null terminator
const SIMPLEBLE_CHARACTERISTIC_MAX_COUNT =16
const SIMPLEBLE_DESCRIPTOR_MAX_COUNT =16


@enum SBLEERROR::Csize_t begin
	SBLESUCCESS =0
	SBLEFAILURE =1
end;

"""
Basically just a fixed length string but can be anything really
"""
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
const NULL_UUID =
	SBLEUUID(zeros(Cchar, SIMPLEBLE_UUID_STR_LEN)
		|> NTuple{SIMPLEBLE_UUID_STR_LEN, Cchar})
function Base.show(io::IO, x::SBLEUUID)
	if x == NULL_UUID
		print(io, "00000000-0000-0000-0000-00000000000")
	else
		print(io, (String∘Vector{UInt8}∘collect)(x.value))
	end
end

struct SBLEDESCRIPTOR
	uuid::SBLEUUID
end
function Base.show(io::IO, x::SBLEDESCRIPTOR)
	print(io, "Descriptor with uuid: $(x.uuid)")
end

"""
Can be written to with `write_request` and `write_command` along with
it's associated `SBLESERVICE`

You can check what Characteristics a peripheral has with `services`
Often a peripheral will not advertise it's services unless it is
connected
"""
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
function Base.show(io::IO, x::SBLECHARACTERISTIC)
	print(io, "Characteristic: uuid:$(x.uuid), read:$(x.can_read), request:$(x.can_write_request), command:$(x.can_write_command), notify:$(x.can_notify), indicate:$(x.can_indicate), descriptor count:$(x.descriptor_count)")
end

"""
You can check what Services a peripheral has with `services`.
Often a peripheral will not advertise it's services unless it is
connected
"""
struct SBLESERVICE
	uuid::SBLEUUID
	data_length::Csize_t
	data::NTuple{27, UInt8}
	characteristic_count::Csize_t
	characteristics::NTuple{SIMPLEBLE_CHARACTERISTIC_MAX_COUNT, SBLECHARACTERISTIC}
end
function Base.show(io::IO, x::SBLESERVICE)
	data_as_string = String(collect(x.data[1:x.data_length]))
	print(io, "Service: uuid:$(x.uuid), data:$data_as_string, characteristic count:$(x.characteristic_count)")
end

"""
Arbitrary data about a peripheral that can be acquired
with `manufacturer_data`
"""
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

# Only ever create a adapter when you know you need to release it
"""
A handle for an adapter that enables bluetooth connectivity on the
device

Can be acquired with `get_adapter(i)`

Windows currently only supports one adapter with `i = 0`
"""
mutable struct Adapter
	ptr::SBLEADAPTER
	function Adapter(x)
		return finalizer(new(x)) do y
			@debug "$(time_ns()): Finalizing Adapter $(y.ptr)"
			y.ptr == C_NULL && return nothing
			ccall(
				(:simpleble_adapter_release_handle, simplecble),
				Cvoid,
				(SBLEADAPTER, ),
				y.ptr
			)
		end
	end
end
Base.unsafe_convert(::Type{SBLEADAPTER}, x::Adapter) = x.ptr

# Only ever create a peripheral when you know you need to release it
"""
A handle for a bluetooth device. You can acquire a specific peripheral
by using `find_peripheral` or get a list of all found peripherals with
`scan_get_results`
"""
mutable struct Peripheral
	ptr::SBLEPERIPHERAL
	subscriptions::Set{Tuple{SBLEUUID,SBLEUUID}}
	function Peripheral(x)
		return finalizer(new(x, Set{Tuple{SBLEUUID,SBLEUUID}}())) do y
			@debug "$(time_ns()): Finalizing Peripheral $(y.ptr)"
			ccall(
				(:simpleble_peripheral_set_callback_on_connected, simplecble),
				SBLEERROR,
				(SBLEPERIPHERAL, Ptr{Cvoid}),
				y.ptr, C_NULL
			)
			ccall(
				(:simpleble_peripheral_set_callback_on_disconnected, simplecble),
				SBLEERROR,
				(SBLEPERIPHERAL, Ptr{Cvoid}),
				y.ptr, C_NULL
			)

			for (s,c) in y.subscriptions
				ccall(
					(:simpleble_peripheral_unsubscribe, simplecble),
					SBLEERROR,
					(SBLEPERIPHERAL, SBLEUUID, SBLEUUID),
					y.ptr, s, c
				)
			end
			empty!(y.subscriptions)
			ccall(
				(:simpleble_peripheral_release_handle, simplecble),
				Cvoid,
				(SBLEPERIPHERAL, ),
				y.ptr
			)
		end
	end
end
Base.unsafe_convert(::Type{SBLEPERIPHERAL}, x::Peripheral) = x.ptr
