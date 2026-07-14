using SimpleBLE, Test

@testset begin
    @test occursin(r"0\.\d+?\.\d+", SimpleBLE.simpleble_get_version())
    @test SimpleBLE.simpleble_get_operating_system() in [SimpleBLE.SIMPLEBLE_OS_LINUX, SimpleBLE.SIMPLEBLE_OS_WINDOWS, SimpleBLE.SIMPLEBLE_OS_MACOS]
end

@testset "SBLEUUID" begin
    NULL_UUID = SimpleBLE.NULL_UUID
    u = SBLEUUID("12345678-1234-1234-1234-123456789abc")
    @test length(u.value) == 37
    @test u.value[37] == 0  # null terminator
    @test repr(u) == "12345678-1234-1234-1234-123456789abc"

    @test repr(NULL_UUID) == "00000000-0000-0000-0000-00000000000"
    @test SBLEUUID("") == NULL_UUID
    @test SBLEUUID("") == SBLEUUID("")

    short = SBLEUUID("abc")
    @test short.value[1] == Cchar('a')
    @test short.value[4] == 0  # rest is null-padded
    @test short != NULL_UUID

    tup = NTuple{37, Cchar}(zeros(Cchar, 37))
    @test SBLEUUID(tup) == NULL_UUID
end

@testset "show methods" begin
    d = SimpleBLE.SBLEDESCRIPTOR(SBLEUUID("abc"))
    @test repr(d) == "Descriptor with uuid: abc\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0"

    descs = ntuple(_ -> SimpleBLE.SBLEDESCRIPTOR(SBLEUUID("")), 16)
    c = SimpleBLE.SBLECHARACTERISTIC(SBLEUUID("xyz"), true, false, true, false, true, Csize_t(0), descs)
    @test occursin("uuid:xyz", repr(c))
    @test occursin("read:true", repr(c))
end

@testset "free" begin
    @test SimpleBLE.free(C_NULL) === nothing
end

@testset "Bluetooth functionality" begin
    if "--bluetooth-on" in ARGS
        @test is_bluetooth_enabled()
        As = get_adapters()
        @test length(As) > 0
        A = As[1]
        @test !isempty(identifier(A))
        @test !isempty(address(A))
        scan_for(A, 1000)
        results = scan_get_results(A)
        @test length(results) > 0
        P = results[1]
        @test !isempty(address(P))
        @test rssi(P) !== nothing
        @test !is_connected(P)
    end
end