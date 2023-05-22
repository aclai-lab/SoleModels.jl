@test_logs (:warn,) SoleModels.parsecondition("min[1] <= 32")
@test_nowarn SoleModels.parsecondition("min[1] <= 32"; featvaltype = Float64)

@test_nowarn SoleModels.parsecondition("min[1] <= 32"; featvaltype = Float64)
@test_nowarn SoleModels.parsecondition("max[2] <= 435"; featvaltype = Float64)
@test_nowarn SoleModels.parsecondition("minimum[6]    > 250.631"; featvaltype = Float64)
@test_nowarn SoleModels.parsecondition("   minimum   [7]    > 11.2"; featvaltype = Float64)
@test_nowarn SoleModels.parsecondition("avg [8]    > 63.2  "; featvaltype = Float64)
@test_nowarn SoleModels.parsecondition("mean[9] <= 1.0e100"; featvaltype = Float64)

@test_nowarn SoleModels.parsecondition("max{3] <= 12"; featvaltype = Float64, opening_bracket="{")
@test_nowarn SoleModels.parsecondition("  min[4}    > 43.25  "; featvaltype = Float64, closing_bracket="}")
@test_nowarn SoleModels.parsecondition("max{5} <= 250"; featvaltype = Float64, opening_bracket="{", closing_bracket="}")
@test_nowarn SoleModels.parsecondition("mean[9] <= 1.0e100"; featvaltype = Float64)
@test_nowarn SoleModels.parsecondition("mean🌅9🌄 <= 1.0e100"; featvaltype = Float64, opening_bracket="🌅", closing_bracket="🌄")

@test_nowarn SoleModels.featvaltype(SoleModels.feature(SoleModels.parsecondition("mean[10]    > 462.2"; featvaltype = Float64))) == Float64
@test_nowarn SoleModels.featvaltype(SoleModels.feature(SoleModels.parsecondition("mean[11]<1.0e100"; featvaltype = Float64))) == Float64

@test_nowarn SoleModels.parsecondition("max[15] <= 723"; featvaltype = Float64)

@test_throws Exception SoleModels.parsecondition("5345.4 < avg [13]    < 32.2 < 12.2")
@test_throws ArgumentError SoleModels.parsecondition("avg [14] < 12.2 <= 6127.2")
@test_throws AssertionError SoleModels.parsecondition("mean189]    > 113.2")
@test_throws AssertionError SoleModels.parsecondition("mean[16] == 54.2")
@test_throws AssertionError SoleModels.parsecondition("123.4 < avg [12]    > 777.2  ")
@test_throws Exception SoleModels.parsecondition("mimimum [17] < 23.2 <= 156.2")
@test_throws AssertionError SoleModels.parsecondition("max[3} <= 12"; opening_bracket="{")
@test_throws AssertionError SoleModels.parsecondition("max{18] <= 12"; opening_bracket="}")
