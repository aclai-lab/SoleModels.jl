@test_logs (:warn,) SoleModels.parsecondition("min[V1] <= 32")
@test_nowarn SoleModels.parsecondition("min[V1] <= 32"; featvaltype = Float64)

@test_nowarn SoleModels.parsecondition("min[V1] <= 32"; featvaltype = Float64)
@test_nowarn SoleModels.parsecondition("max[V2] <= 435"; featvaltype = Float64)
@test_nowarn SoleModels.parsecondition("minimum[V6]    > 250.631"; featvaltype = Float64)
@test_nowarn SoleModels.parsecondition("   minimum   [V7]    > 11.2"; featvaltype = Float64)
@test_nowarn SoleModels.parsecondition("avg [V8]    > 63.2  "; featvaltype = Float64)
@test_nowarn SoleModels.parsecondition("mean[V9] <= 1.0e100"; featvaltype = Float64)

@test_nowarn SoleModels.parsecondition("max{3] <= 12"; featvaltype = Float64, opening_bracket="{", attribute_name_prefix = "")
@test_nowarn SoleModels.parsecondition("  min[V4}    > 43.25  "; featvaltype = Float64, closing_bracket="}")
@test_nowarn SoleModels.parsecondition("max{5} <= 250"; featvaltype = Float64, opening_bracket="{", closing_bracket="}", attribute_name_prefix = "")
@test_nowarn SoleModels.parsecondition("mean[V9] <= 1.0e100"; featvaltype = Float64)
@test_nowarn SoleModels.parsecondition("mean🌅V9🌄 <= 1.0e100"; featvaltype = Float64, opening_bracket="🌅", closing_bracket="🌄")

@test_nowarn SoleModels.featvaltype(SoleModels.feature(SoleModels.parsecondition("mean[V10]    > 462.2"; featvaltype = Float64))) == Float64
@test_nowarn SoleModels.featvaltype(SoleModels.feature(SoleModels.parsecondition("mean[V11]<1.0e100"; featvaltype = Float64))) == Float64

@test_nowarn SoleModels.parsecondition("max[V15] <= 723"; featvaltype = Float64)
@test_nowarn SoleModels.parsecondition("mean[V16] == 54.2")

@test_throws Exception SoleModels.parsecondition("5345.4 < avg [V13]    < 32.2 < 12.2")
@test_throws AssertionError SoleModels.parsecondition("avg [V14] < 12.2 <= 6127.2")
@test_throws AssertionError SoleModels.parsecondition("mean189]    > 113.2")
@test_throws AssertionError SoleModels.parsecondition("123.4 < avg [V12]    > 777.2  ")
@test_throws Exception SoleModels.parsecondition("mimimum [V17] < 23.2 <= 156.2")
@test_throws AssertionError SoleModels.parsecondition("max[V3} <= 12"; opening_bracket="{")
@test_throws AssertionError SoleModels.parsecondition("max{18] <= 12"; opening_bracket="}", attribute_name_prefix = "")
