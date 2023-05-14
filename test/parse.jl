@test_nowarn SoleModels.parsecondition("min[189] <= 250")
@test_nowarn SoleModels.parsecondition("max[189] <= 250")
@test_nowarn SoleModels.parsecondition("  min[189]    > 250.2  ")
@test_nowarn SoleModels.parsecondition("minimum[189]    > 250.2")
@test_nowarn SoleModels.parsecondition("   minimum   [189]    > 250.2")
@test_nowarn SoleModels.parsecondition("avg [189]    > 250.2  ")
@test_nowarn SoleModels.parsecondition("mean[189] <= 1.0e100")

@test_nowarn SoleModels.featvaltype(SoleModels.feature(
    SoleModels.parsecondition("mean[189]    > 250.2"; featvaltype = Float64))) == Float64
@test_nowarn SoleModels.featvaltype(SoleModels.feature(
    SoleModels.parsecondition("mean[189]<1.0e100"; featvaltype = Float64))) == Float64

# This gives no error, since regexp is matching correctly, but "123.4 <" is ignored
@test_nowarn SoleModels.parsecondition("123.4 < avg [189]    > 250.2  ")

@test_throws ArgumentError SoleModels.parsecondition("123.4 < avg [189]    < 250.2 < 251.2")
@test_throws ArgumentError SoleModels.parsecondition("avg [189] < 250.2 <= 251.2")
@test_throws ArgumentError SoleModels.parsecondition("max[A189] <= 250")
@test_throws AssertionError SoleModels.parsecondition("mean189]    > 250.2")
@test_throws AssertionError SoleModels.parsecondition("mean[189] == 250.2")
@test_throws UndefVarError SoleModels.parsecondition("mimimum [189] < 250.2 <= 251.2")
