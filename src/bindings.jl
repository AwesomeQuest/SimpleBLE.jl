
import Base

export adapter_get_count, 
	adapter_get_handle, 
	adapter_set_callback_on_scan_start,
	adapter_set_callback_on_scan_stop,
	adapter_set_callback_on_scan_found,
	adapter_set_callback_on_scan_updated,
	adapter_scan_for,
	adapter_scan_get_results_count,
	adapter_scan_get_results_handle,
	peripheral_identifier,
	peripheral_address,
	peripheral_is_connectable,
	peripheral_connect,
	peripheral_disconnect,
	peripheral_rssi,
	peripheral_services_count,
	peripheral_services_get,
	peripheral_manufacturer_data_count,
	peripheral_manufacturer_data_get,
	peripheral_release_handle,
	peripheral_write_request,
	peripheral_write_command,
	peripheral_write_descriptor,
	peripheral_read,
	peripheral_read_descriptor,
	peripheral_notify,
	peripheral_indicate,
	simpleble_free,
	adapter_release_handle,
	adapter_identifier

const simpleblepath = joinpath(@__DIR__, "..", "shared", "bin", "simplecble.dll")

const _active_callbacks = Dict{Ptr{Cvoid}, Base.CFunction}()

const SIMPLEBLE_UUID_STR_LEN =37  # 36 characters + null terminator
const SIMPLEBLE_CHARACTERISTIC_MAX_COUNT =16
const SIMPLEBLE_DESCRIPTOR_MAX_COUNT =16

@enum SimpleBLE_Error::Csize_t begin 
	SIMPLEBLE_SUCCESS =0
	SIMPLEBLE_FAILURE =1
end;

struct SBLEUUID 
	value::NTuple{SIMPLEBLE_UUID_STR_LEN, Cchar};
	SBLEUUID(s) = s
	function SBLEUUID(s::T) where T <: AbstractString
		s = codeunits(s)
		out = zeros(Cchar, SIMPLEBLE_UUID_STR_LEN)
		out[1:min(length(s), SIMPLEBLE_UUID_STR_LEN)] .= s
		return new(NTuple{SIMPLEBLE_UUID_STR_LEN, Cchar}(out))
	end
end;
const NULL_UUID = SBLEUUID(zeros(Cchar, SIMPLEBLE_UUID_STR_LEN) |> NTuple{SIMPLEBLE_UUID_STR_LEN, Cchar})
function Base.show(io::IO, x::SBLEUUID)
	if x == NULL_UUID
		print(io, "00000000-0000-0000-0000-00000000000")
	else
		print(io, (String∘Vector{UInt8}∘collect)(x.value))
	end
end

struct Descriptor
	uuid::SBLEUUID
end;

struct SBLECharacteristic
	uuid::SBLEUUID
	can_read::Bool
	can_write_request::Bool
	can_write_command::Bool
	can_notify::Bool
	can_indicate::Bool
	descriptor_count::Csize_t
	descriptors::NTuple{SIMPLEBLE_DESCRIPTOR_MAX_COUNT, Descriptor};
end;

struct SBLEService
	uuid::SBLEUUID
	data_length::Csize_t
	data::NTuple{27, UInt8};
	# Note: The maximum length of a BLE advertisement is 31 bytes.
	# The first byte will be the length of the field,
	# the second byte will be the type of the field,
	# the next two bytes will be the service UUID,
	# and the remaining 27 bytes are the manufacturer data.
	characteristic_count::Csize_t
	characteristics::NTuple{SIMPLEBLE_CHARACTERISTIC_MAX_COUNT, SBLECharacteristic};
end;

struct Manufacturer_Data 
	manufacturer_id::UInt16
	data_length::Csize_t
	data::NTuple{27, UInt8};
	# Note: The maximum length of a BLE advertisement is 31 bytes.
	# The first byte will be the length of the field,
	# the second byte will be the type of the field (0xFF for manufacturer data),
	# the next two bytes will be the manufacturer ID,
	# and the remaining 27 bytes are the manufacturer data.
end;

const SBLEAdapter = Ptr{Cvoid};
# struct Adapter val::SBLEAdapter end
# Base.cconvert(::Type{SBLEAdapter}, x::Adapter) = x.val
const SBLEPeripheral = Ptr{Cvoid};
# struct Peripheral val::SBLEPeripheral end
# Base.cconvert(::Type{SBLEPeripheral}, x::Peripheral) = x.val

@enum SimpleBLE_OS::Csize_t begin 
	SIMPLEBLE_OS_WINDOWS =0
	SIMPLEBLE_OS_MACOS =1
	SIMPLEBLE_OS_LINUX =2
end;

@enum SimpleBLE_Address_Type::Csize_t begin 
	SIMPLEBLE_ADDRESS_TYPE_PUBLIC =0
	SIMPLEBLE_ADDRESS_TYPE_RANDOM =1
	SIMPLEBLE_ADDRESS_TYPE_UNSPECIFIED =2
end;


function adapter_address(handle::SBLEAdapter)
	sblestring = _adapter_address(handle)
	GC.@preserve sblestring begin
		output = unsafe_string(sblestring)
		# simpleble_free(sblestring)
	end
	return output
end
_adapter_address(handle::SBLEAdapter) =
	@ccall simpleblepath.simpleble_adapter_address(
		handle::SBLEAdapter)::Cstring

adapter_get_connected_peripherals_count(handle::SBLEAdapter) =
	@ccall simpleblepath.simpleble_adapter_get_connected_peripherals_count(
		handle::SBLEAdapter)::Csize_t

adapter_get_connected_peripherals_handle(handle::SBLEAdapter, index) =
	@ccall simpleblepath.simpleble_adapter_get_connected_peripherals_handle(
		handle::SBLEAdapter,  index::Csize_t)::SBLEPeripheral

adapter_get_count() =
	@ccall simpleblepath.simpleble_adapter_get_count(
		)::Csize_t

adapter_get_handle(index) =
	@ccall simpleblepath.simpleble_adapter_get_handle(
		index::Csize_t)::SBLEAdapter

adapter_get_paired_peripherals_count(handle::SBLEAdapter) =
	@ccall simpleblepath.simpleble_adapter_get_paired_peripherals_count(
		handle::SBLEAdapter)::Csize_t

adapter_get_paired_peripherals_handle(handle::SBLEAdapter, index) =
	@ccall simpleblepath.simpleble_adapter_get_paired_peripherals_handle(
		handle::SBLEAdapter,  index::Csize_t)::SBLEPeripheral

function adapter_identifier(handle::SBLEAdapter)
	sblestring = _adapter_identifier(handle)
	GC.@preserve sblestring begin
		output = unsafe_string(sblestring)
		# simpleble_free(sblestring)
	end
	return output
end
_adapter_identifier(handle::SBLEAdapter) =
	@ccall simpleblepath.simpleble_adapter_identifier(
		handle::SBLEAdapter)::Cstring

adapter_is_bluetooth_enabled() =
	@ccall simpleblepath.simpleble_adapter_is_bluetooth_enabled(
		)::Bool

adapter_is_powered(handle::SBLEAdapter, powered) =
	@ccall simpleblepath.simpleble_adapter_is_powered(
		handle::SBLEAdapter, powered::Ptr{Bool})::SimpleBLE_Error

adapter_power_off(handle::SBLEAdapter) =
	@ccall simpleblepath.simpleble_adapter_power_off(
		handle::SBLEAdapter)::SimpleBLE_Error

adapter_power_on(handle::SBLEAdapter) =
	@ccall simpleblepath.simpleble_adapter_power_on(
		handle::SBLEAdapter)::SimpleBLE_Error

adapter_release_handle(handle::SBLEAdapter) =
	@ccall simpleblepath.simpleble_adapter_release_handle(
		handle::SBLEAdapter)::Cvoid

adapter_scan_for(handle::SBLEAdapter, timeout_ms) =
	@ccall simpleblepath.simpleble_adapter_scan_for(
		handle::SBLEAdapter,  timeout_ms::Csize_t)::SimpleBLE_Error

adapter_scan_get_results_count(handle::SBLEAdapter) =
	@ccall simpleblepath.simpleble_adapter_scan_get_results_count(
		handle::SBLEAdapter)::Csize_t

adapter_scan_get_results_handle(handle::SBLEAdapter, index) =
	@ccall simpleblepath.simpleble_adapter_scan_get_results_handle(
		handle::SBLEAdapter,  index::Csize_t)::SBLEPeripheral

adapter_scan_is_active(handle::SBLEAdapter, active) =
	@ccall simpleblepath.simpleble_adapter_scan_is_active(
		handle::SBLEAdapter, active::Ptr{Bool})::SimpleBLE_Error

adapter_scan_start(handle::SBLEAdapter) =
	@ccall simpleblepath.simpleble_adapter_scan_start(
		handle::SBLEAdapter)::SimpleBLE_Error

adapter_scan_stop(handle::SBLEAdapter) =
	@ccall simpleblepath.simpleble_adapter_scan_stop(
		handle::SBLEAdapter)::SimpleBLE_Error

function adapter_set_callback_on_power_off(handle, callback, userdata)
	c_callback = @cfunction($callback, Cvoid, (SBLEAdapter, Ptr{Cvoid}))
	_active_callbacks[handle] = c_callback  # prevent GC
	_adapter_set_callback_on_power_off(handle, c_callback, userdata)
end
_adapter_set_callback_on_power_off(handle::SBLEAdapter, callback, userdata) =
	@ccall simpleblepath.simpleble_adapter_set_callback_on_power_off(
	handle::SBLEAdapter, callback::Ptr{Cvoid}, userdata::Ptr{Cvoid})::SimpleBLE_Error


function adapter_set_callback_on_power_on(handle::SBLEAdapter, callback, userdata)
	c_callback = @cfunction($callback, Cvoid, (SBLEAdapter, Ptr{Cvoid}))
	_active_callbacks[handle] = c_callback  # prevent GC
	_adapter_set_callback_on_power_on(handle, c_callback, userdata)
end
_adapter_set_callback_on_power_on(handle::SBLEAdapter, callback, userdata) =
	@ccall simpleblepath.simpleble_adapter_set_callback_on_power_on(
		handle::SBLEAdapter, callback::Ptr{Cvoid}, userdata::Ptr{Cvoid})::SimpleBLE_Error


function adapter_set_callback_on_scan_found(handle::SBLEAdapter, callback, userdata)
	c_callback = @cfunction($callback, Cvoid, (SBLEAdapter, SBLEPeripheral, Ptr{Cvoid}))
	_active_callbacks[handle] = c_callback  # prevent GC
	_adapter_set_callback_on_scan_found(handle, c_callback, userdata)
end
_adapter_set_callback_on_scan_found(handle::SBLEAdapter, callback,userdata) =
	@ccall simpleblepath.simpleble_adapter_set_callback_on_scan_found(
		handle::SBLEAdapter, callback::Ptr{Cvoid},userdata::Ptr{Cvoid})::SimpleBLE_Error

function adapter_set_callback_on_scan_start(handle::SBLEAdapter, callback, userdata)
	c_callback = @cfunction($callback, Cvoid, (SBLEAdapter, Ptr{Cvoid}))
	_active_callbacks[handle] = c_callback  # prevent GC
	_adapter_set_callback_on_scan_start(handle, c_callback, userdata)
end
_adapter_set_callback_on_scan_start(handle::SBLEAdapter, callback,userdata) =
	@ccall simpleblepath.simpleble_adapter_set_callback_on_scan_start(
		handle::SBLEAdapter, callback::Ptr{Cvoid}, userdata::Ptr{Cvoid})::SimpleBLE_Error


function adapter_set_callback_on_scan_stop(handle::SBLEAdapter, callback, userdata)
	c_callback = @cfunction($callback, Cvoid, (SBLEAdapter, Ptr{Cvoid}))
	_active_callbacks[handle] = c_callback  # prevent GC
	_adapter_set_callback_on_scan_stop(handle, c_callback, userdata)
end
_adapter_set_callback_on_scan_stop(handle::SBLEAdapter, callback,userdata) =
	@ccall simpleblepath.simpleble_adapter_set_callback_on_scan_stop(
		handle::SBLEAdapter, callback::Ptr{Cvoid}, userdata::Ptr{Cvoid})::SimpleBLE_Error

function adapter_set_callback_on_scan_updated(handle::SBLEAdapter, callback, userdata)
	c_callback = @cfunction($callback, Cvoid, (SBLEAdapter, SBLEPeripheral, Ptr{Cvoid}))
	_active_callbacks[handle] = c_callback  # prevent GC
	_adapter_set_callback_on_scan_updated(handle, c_callback, userdata)
end
_adapter_set_callback_on_scan_updated(handle::SBLEAdapter, callback,userdata) =
	@ccall simpleblepath.simpleble_adapter_set_callback_on_scan_updated(
		handle::SBLEAdapter, callback::Ptr{Cvoid}, userdata::Ptr{Cvoid})::SimpleBLE_Error

adapter_underlying(handle::SBLEAdapter) =
	@ccall simpleblepath.simpleble_adapter_underlying(
		handle::SBLEAdapter)::Ptr{Cvoid}

function simpleble_free(handle::Cstring)
	simpleble_free(pointer(handle))
end
simpleble_free(handle) =
	@ccall simpleblepath.simpleble_free(
		handle::Ptr{Cvoid})::Cvoid

get_operating_system() =
	@ccall simpleblepath.simpleble_get_operating_system(
		)::SimpleBLE_OS

function get_version()
	sblestring = _get_version()
	GC.@preserve sblestring begin
		output = unsafe_string(sblestring)
		# simpleble_free(sblestring)
	end
	return output
end
_get_version() =
	@ccall simpleblepath.simpleble_get_version(
		)::Cstring

@enum SimpleBLE_Log_Level::Csize_t begin 
	SIMPLEBLE_LOG_LEVEL_NONE = 0
	SIMPLEBLE_LOG_LEVEL_FATAL
	SIMPLEBLE_LOG_LEVEL_ERROR
	SIMPLEBLE_LOG_LEVEL_WARN
	SIMPLEBLE_LOG_LEVEL_INFO
	SIMPLEBLE_LOG_LEVEL_DEBUG
	SIMPLEBLE_LOG_LEVEL_VERBOSE
end
logging_set_level(level) =
	@ccall simpleblepath.simpleble_logging_set_level(
		level::SimpleBLE_Log_Level)::Cvoid

function logging_set_callback(callback)
	c_callback = @cfunction($callback, Cvoid, (SimpleBLE_Log_Level, Cstring, Cstring, UInt32, Cstring, Cstring))
	_active_callbacks[handle] = c_callback  # prevent GC
	_logging_set_callback(c_callback)
end
_logging_set_callback(callback) =
	@ccall simpleblepath.simpleble_logging_set_callback(
		callback::Ptr{Cvoid})::Cvoid

function peripheral_address(handle::SBLEPeripheral)
	sblestring = _peripheral_address(handle)
	GC.@preserve sblestring begin
		output = unsafe_string(sblestring)
		# simpleble_free(sblestring)
	end
	return output
end
_peripheral_address(handle::SBLEPeripheral) =
	@ccall simpleblepath.simpleble_peripheral_address(
		handle::SBLEPeripheral)::Cstring

peripheral_address_type(handle::SBLEPeripheral) =
	@ccall simpleblepath.simpleble_peripheral_address_type(
		handle::SBLEPeripheral)::SimpleBLE_Address_Type

peripheral_connect(handle::SBLEPeripheral) =
	@ccall simpleblepath.simpleble_peripheral_connect(
		handle::SBLEPeripheral)::SimpleBLE_Error

peripheral_disconnect(handle::SBLEPeripheral) =
	@ccall simpleblepath.simpleble_peripheral_disconnect(
		handle::SBLEPeripheral)::SimpleBLE_Error


function peripheral_identifier(handle::SBLEAdapter)
	sblestring = _peripheral_identifier(handle)
	GC.@preserve sblestring begin
		output = unsafe_string(sblestring)
		# simpleble_free(sblestring)
	end
	return output
end
_peripheral_identifier(handle::SBLEPeripheral) =
	@ccall simpleblepath.simpleble_peripheral_identifier(
		handle::SBLEPeripheral)::Cstring

#=
callback takes 
(
handle::simpleble_peripheral_t,
service::simpleble_uuid_t,
characteristic::simpleble_uuid_t,
data::Ptr{Ptr{UInt8}}, data_length::Ptr{Csize_t}, 
userdata::Ptr{Cvoid}
)
=#
function peripheral_indicate(handle::SBLEPeripheral, service, characteristic, callback)
	function c_callback(handle, service, characteristic, data, data_length, userdata)
		jdata = unsafe_wrap(Vector{UInt8}, data, data_length)
		callback(jdata)
		# simpleble_free(data)
	end
	peripheral_indicate(handle, service, characteristic, c_callback,C_NULL)
end
function peripheral_indicate(handle, service, characteristic, callback, userdata)
	c_callback = @cfunction($callback, Cvoid, (SBLEPeripheral, SBLEUUID, SBLEUUID, Ptr{UInt8},Csize_t, Ptr{Cvoid}))
	_active_callbacks[handle] = c_callback  # prevent GC
	_peripheral_indicate(handle, service, characteristic, c_callback, userdata)
end
_peripheral_indicate(handle::SBLEPeripheral, service, characteristic, callback, userdata) =
	@ccall simpleblepath.simpleble_peripheral_indicate(
		handle::SBLEPeripheral,
		service::SBLEUUID,
		characteristic::SBLEUUID,
		callback::Ptr{Cvoid},
		userdata::Ptr{Cvoid})::SimpleBLE_Error

peripheral_is_connectable(handle::SBLEPeripheral, connectable) =
	@ccall simpleblepath.simpleble_peripheral_is_connectable(
		handle::SBLEPeripheral, connectable::Ptr{Bool})::SimpleBLE_Error

peripheral_is_connected(handle::SBLEPeripheral, connected) =
	@ccall simpleblepath.simpleble_peripheral_is_connected(
		handle::SBLEPeripheral, connected::Ptr{Bool})::SimpleBLE_Error

peripheral_is_paired(handle::SBLEPeripheral, paired) =
	@ccall simpleblepath.simpleble_peripheral_is_paired(
		handle::SBLEPeripheral, paired::Ptr{Bool})::SimpleBLE_Error

peripheral_manufacturer_data_count(handle::SBLEPeripheral) =
	@ccall simpleblepath.simpleble_peripheral_manufacturer_data_count(
		handle::SBLEPeripheral)::Csize_t

peripheral_manufacturer_data_get(handle::SBLEPeripheral, index, manufacturer_data) =
	@ccall simpleblepath.simpleble_peripheral_manufacturer_data_get(
		handle::SBLEPeripheral, 
		index::Csize_t, 
		manufacturer_data::Ptr{Manufacturer_Data})::SimpleBLE_Error

peripheral_mtu(handle::SBLEPeripheral) =
	@ccall simpleblepath.simpleble_peripheral_mtu(
		handle::SBLEPeripheral)::UInt16

#=
callback takes 
(
handle::simpleble_peripheral_t,
service::simpleble_uuid_t,
characteristic::simpleble_uuid_t,
data::Ptr{UInt8}, data_length::Csize_t, 
userdata::Ptr{Cvoid}
)
=#
function peripheral_notify(handle::SBLEPeripheral, service, characteristic, callback)
	function c_callback(handle, service, characteristic, data, data_length, userdata)
		jdata = unsafe_wrap(Vector{UInt8}, data, data_length)
		callback(jdata)
		# simpleble_free(data)
	end
	GC.@preserve callback c_callback begin
		peripheral_notify(handle, service, characteristic, c_callback, C_NULL)
	end
end
function peripheral_notify(handle::SBLEPeripheral, service, characteristic, callback, userdata)
	c_callback = @cfunction($callback, Cvoid, (SBLEPeripheral, SBLEUUID, SBLEUUID, Ptr{UInt8},Csize_t, Ptr{Cvoid}))
	_active_callbacks[handle] = c_callback  # prevent GC
	_peripheral_notify(handle, service, characteristic, c_callback, userdata)
end
_peripheral_notify(handle::SBLEPeripheral, service, characteristic, callback, userdata) =
	@ccall simpleblepath.simpleble_peripheral_notify(
		handle::SBLEPeripheral,
		service::SBLEUUID,
		characteristic::SBLEUUID,
		callback::Ptr{Cvoid},
		userdata::Ptr{Cvoid})::SimpleBLE_Error

peripheral_read(handle::SBLEPeripheral, service, characteristic, data, data_length) =
	@ccall simpleblepath.simpleble_peripheral_read(
		handle::SBLEPeripheral,
		service::SBLEUUID,
		characteristic::SBLEUUID,
		data::Ptr{Ptr{UInt8}}, data_length::Ptr{Csize_t})::SimpleBLE_Error

peripheral_read_descriptor(handle::SBLEPeripheral, service, characteristic, descriptor, data, data_length) =
	@ccall simpleblepath.simpleble_peripheral_read_descriptor(
		handle::SBLEPeripheral,
		service::SBLEUUID,
		characteristic::SBLEUUID,
		descriptor::SBLEUUID,
		data::Ptr{Ptr{UInt8}}, data_length::Ptr{Csize_t})::SimpleBLE_Error

peripheral_release_handle(handle::SBLEPeripheral) =
	@ccall simpleblepath.simpleble_peripheral_release_handle(
		handle::SBLEPeripheral)::Cvoid

peripheral_rssi(handle::SBLEPeripheral) =
	@ccall simpleblepath.simpleble_peripheral_rssi(
		handle::SBLEPeripheral)::UInt16

peripheral_services_count(handle::SBLEPeripheral) =
	@ccall simpleblepath.simpleble_peripheral_services_count(
		handle::SBLEPeripheral)::Csize_t

peripheral_services_get(handle::SBLEPeripheral, index, services) =
	@ccall simpleblepath.simpleble_peripheral_services_get(
		handle::SBLEPeripheral, 
		index::Csize_t, 
		services::Ptr{SBLEService})::SimpleBLE_Error

#=
callback takes 
(
 peripheral::simpleble_peripheral_t, 
userdata::Ptr{Cvoid}
)
=#
function peripheral_set_callback_on_connected(handle, callback, userdata)
	c_callback = @cfunction($callback, Cvoid, (SBLEPeripheral, Ptr{Cvoid}))
	_active_callbacks[handle] = c_callback  # prevent GC
	_peripheral_set_callback_on_connected(handle, c_callback, userdata)
end
_peripheral_set_callback_on_connected(handle::SBLEPeripheral, callback, userdata) =
	@ccall simpleblepath.simpleble_peripheral_set_callback_on_connected(
		handle::SBLEPeripheral,
		callback::Ptr{Cvoid},
		userdata::Ptr{Cvoid})::SimpleBLE_Error

#=
callback takes 
(
 peripheral::simpleble_peripheral_t, 
userdata::Ptr{Cvoid}
)
=#
function peripheral_set_callback_on_disconnected(handle, callback, userdata)
	c_callback = @cfunction($callback, Cvoid, (SBLEPeripheral, Ptr{Cvoid}))
	_active_callbacks[handle] = c_callback  # prevent GC
	_peripheral_set_callback_on_disconnected(handle, c_callback, userdata)
end
_peripheral_set_callback_on_disconnected(handle::SBLEPeripheral, callback, userdata) =
	@ccall simpleblepath.simpleble_peripheral_set_callback_on_disconnected(
		handle::SBLEPeripheral,
		callback::Ptr{Cvoid},
		userdata::Ptr{Cvoid})::SimpleBLE_Error

peripheral_tx_power(handle::SBLEPeripheral) =
	@ccall simpleblepath.simpleble_peripheral_tx_power(
		handle::SBLEPeripheral)::UInt16

peripheral_underlying(handle::SBLEPeripheral) =
	@ccall simpleblepath.simpleble_peripheral_underlying(
		handle::SBLEPeripheral)::Ptr{Cvoid}

peripheral_unpair(handle::SBLEPeripheral) =
	@ccall simpleblepath.simpleble_peripheral_unpair(
		handle::SBLEPeripheral)::SimpleBLE_Error

peripheral_unsubscribe(handle::SBLEPeripheral, service, characteristic) =
	@ccall simpleblepath.simpleble_peripheral_unsubscribe(
		handle::SBLEPeripheral,
		service::SBLEUUID,
		characteristic::SBLEUUID,)::SimpleBLE_Error

function peripheral_write_command(handle, service, characteristic, data::T) where T<:AbstractString
	cdata = codeunits(data)
	peripheral_write_command(handle, service, characteristic, cdata)
end
function peripheral_write_command(handle::SBLEPeripheral, service::SBLEService, characteristic::SBLECharacteristic, data)
	peripheral_write_command(handle, service.uuid, characteristic.uuid, data)
end
function peripheral_write_command(handle::SBLEPeripheral, service::SBLEUUID, characteristic::SBLEUUID, data::T) where T<:AbstractString
	cdata = codeunits(data)
	peripheral_write_command(handle, service, characteristic, cdata)
end
function peripheral_write_command(handle::SBLEPeripheral, service::SBLEUUID, characteristic::SBLEUUID, data::T) where T<:AbstractArray
	_peripheral_write_command(handle, service, characteristic, data, length(data))
end
_peripheral_write_command(handle::SBLEPeripheral, service, characteristic, data, data_length) =
	@ccall simpleblepath.simpleble_peripheral_write_command(
		handle::SBLEPeripheral,
		service::SBLEUUID,
		characteristic::SBLEUUID,
		data::Ptr{UInt8}, data_length::Csize_t)::SimpleBLE_Error

peripheral_write_descriptor(handle::SBLEPeripheral, service, characteristic, descriptor, data, data_length) =
	@ccall simpleblepath.simpleble_peripheral_write_descriptor(
		handle::SBLEPeripheral,
		service::SBLEUUID,
		characteristic::SBLEUUID,
		descriptor::SBLEUUID,
		data::Ptr{UInt8}, data_length::Csize_t)::SimpleBLE_Error


function peripheral_write_request(handle, service, characteristic, data::T) where T<:AbstractString
	cdata = codeunits(data)
	peripheral_write_request(handle, service, characteristic, cdata)
end
function peripheral_write_request(handle::SBLEPeripheral, service::SBLEService, characteristic::SBLECharacteristic, data)
	peripheral_write_request(handle, service.uuid, characteristic.uuid, data)
end
function peripheral_write_request(handle::SBLEPeripheral, service::SBLEUUID, characteristic::SBLEUUID, data::T) where T<:AbstractString
	cdata = codeunits(data)
	peripheral_write_request(handle, service, characteristic, cdata)
end
function peripheral_write_request(handle::SBLEPeripheral, service::SBLEUUID, characteristic::SBLEUUID, data::T) where T<:AbstractArray
	_peripheral_write_request(handle, service, characteristic, data, length(data))
end
_peripheral_write_request(handle::SBLEPeripheral, service, characteristic, data, data_length) =
	@ccall simpleblepath.simpleble_peripheral_write_request(
		handle::SBLEPeripheral,
		service::SBLEUUID,
		characteristic::SBLEUUID,
		data::Ptr{UInt8}, data_length::Csize_t)::SimpleBLE_Error
