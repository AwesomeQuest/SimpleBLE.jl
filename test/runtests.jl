using SimpleBLE, Test

@testset begin
    @test occursin(r"0\.\d+?\.\d+", SimpleBLE.simpleble_get_version())
    @test SimpleBLE.simpleble_get_operating_system() in [SimpleBLE.SIMPLEBLE_OS_LINUX, SimpleBLE.SIMPLEBLE_OS_WINDOWS, SimpleBLE.SIMPLEBLE_OS_MACOS]
end
@testset begin
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