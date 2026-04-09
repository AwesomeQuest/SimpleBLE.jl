# SimpleBLE.jl

SimpleBLE is a cross-platform bluetooth low energy (BLE) library,
designed for simplicity and ease of use.

## Simple example

```julia
# Get an adapter that will handle requests
adapter = get_adapter(0)
# Find a peripheral using adapter
peripheral = find_peripheral(adapter) do id
    occursin("peripheral name", id)
end
id = identifier(peripheral)
connect(peripheral) do
    SERVICE = "de8d0b82-c7cd-0f33-d15d-c38e1f26673f"
    CHARACTER = "6706b606-0c12-3976-ddba-909377d43dc5"
    notify(peripheral, SERVICE, CHARACTER) do data
        # make sure not to pass the data handle outside the callback
        # it is not valid data once this callback is over, if you need to keep it, copy it
        println("$id received data:")
        println(String(data))
    end
    println("Press enter to stop listening")
    readline()
    unsubscribe(peripheral, SERVICE, CHARACTER)
end
```

## Most common functions
```@docs ; canonical=false
get_adapter
```
```@docs
find_peripheral
```
```@docs ; canonical=false
identifier
address
connect
set_callback_on_scan_found
notify
write_request
peripheral_read
```