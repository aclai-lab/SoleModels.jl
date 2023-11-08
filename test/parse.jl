using Test
using Logging
using SoleModels
using SoleModels: parsecondition

@test_nowarn SoleModels.parsefeature(SoleModels.VarFeature, "min[V1]")
@test_nowarn SoleModels.parsefeature(SoleModels.VarFeature, "min[V1]"; featvaltype = Float64)
@test_nowarn SoleModels.parsefeature(SoleModels.VarFeature, "min[V1]"; featvaltype = Int64)
@test_nowarn SoleModels.parsefeature(SoleModels.AbstractUnivariateFeature, "min[V1]")
# @test_logs (:warn,) SoleModels.parsefeature(UnivariateMin, "min[V1]")
@test_nowarn SoleModels.parsefeature(UnivariateMin, "min[V1]")



@test_logs (:warn,) parsecondition(SoleModels.ScalarCondition, "F1 > 2"; featuretype = SoleModels.Feature)
@test_logs (:warn,) parsecondition(SoleModels.ScalarCondition, "1 > 2"; featuretype = SoleModels.Feature{Int})

C = SoleModels.ScalarCondition

@test_logs min_level=Logging.Error SoleModels.parsecondition(C, "min[V1] <= 32")
@test_logs (:warn,) SoleModels.parsecondition(C, "min[V1] <= 32"; featvaltype = Float64)
@test_nowarn SoleModels.parsecondition(C, "min[V1] <= 32"; featvaltype = Float64, featuretype = SoleModels.AbstractUnivariateFeature)

@test_nowarn SoleModels.parsecondition(C, "min[V1] <= 32"; featvaltype = Float64, featuretype = SoleModels.AbstractUnivariateFeature)
@test_nowarn SoleModels.parsecondition(C, "max[V2] <= 435"; featvaltype = Float64, featuretype = SoleModels.AbstractUnivariateFeature)
@test_nowarn SoleModels.parsecondition(C, "minimum[V6]    > 250.631"; featvaltype = Float64, featuretype = SoleModels.AbstractUnivariateFeature)
@test_throws AssertionError SoleModels.parsecondition(C, "   minimum   [V7]    > 11.2"; featvaltype = Float64, featuretype = SoleModels.AbstractUnivariateFeature)
@test_throws AssertionError SoleModels.parsecondition(C, "avg [V8]    > 63.2  "; featvaltype = Float64, featuretype = SoleModels.AbstractUnivariateFeature)
@test_nowarn SoleModels.parsecondition(C, "mean[V9] <= 1.0e100"; featvaltype = Float64, featuretype = SoleModels.AbstractUnivariateFeature)

@test_nowarn SoleModels.parsecondition(C, "max{3] <= 12"; featvaltype = Float64, opening_bracket="{", variable_name_prefix = "", featuretype = SoleModels.AbstractUnivariateFeature)
@test_nowarn SoleModels.parsecondition(C, "  min[V4}    > 43.25  "; featvaltype = Float64, closing_bracket="}", featuretype = SoleModels.AbstractUnivariateFeature)
@test_nowarn SoleModels.parsecondition(C, "max{5} <= 250"; featvaltype = Float64, opening_bracket="{", closing_bracket="}", variable_name_prefix = "", featuretype = SoleModels.AbstractUnivariateFeature)
@test_nowarn SoleModels.parsecondition(C, "mean[V9] <= 1.0e100"; featvaltype = Float64, featuretype = SoleModels.AbstractUnivariateFeature)
@test_nowarn SoleModels.parsecondition(C, "mean🌅V9🌄 <= 1.0e100"; featvaltype = Float64, opening_bracket="🌅", closing_bracket="🌄", featuretype = SoleModels.AbstractUnivariateFeature)

@test_nowarn SoleModels.feature(SoleModels.parsecondition(C, "mean[V10]    > 462.2"; featvaltype = Float64, featuretype = SoleModels.AbstractUnivariateFeature))
@test_nowarn SoleModels.feature(SoleModels.parsecondition(C, "mean[V11] < 1.0e100"; featvaltype = Float64, featuretype = SoleModels.AbstractUnivariateFeature))


@test_nowarn SoleModels.parsecondition(C, "max[V15] <= 723"; featvaltype = Float64, featuretype = SoleModels.AbstractUnivariateFeature)
@test_nowarn SoleModels.parsecondition(C, "mean[V16] == 54.2"; featvaltype = Float64, featuretype = SoleModels.AbstractUnivariateFeature)

@test_throws Exception SoleModels.parsecondition(C, "5345.4 < avg [V13]    < 32.2 < 12.2"; featuretype = SoleModels.AbstractUnivariateFeature)
@test_throws AssertionError SoleModels.parsecondition(C, "avg [V14] < 12.2 <= 6127.2"; featuretype = SoleModels.AbstractUnivariateFeature)
@test_throws AssertionError SoleModels.parsecondition(C, "mean189]    > 113.2"; featuretype = SoleModels.AbstractUnivariateFeature)
@test_throws AssertionError SoleModels.parsecondition(C, "123.4 < avg [V12]    > 777.2  "; featuretype = SoleModels.AbstractUnivariateFeature)
@test_throws Exception SoleModels.parsecondition(C, "mimimum [V17] < 23.2 <= 156.2"; featuretype = SoleModels.AbstractUnivariateFeature)
@test_throws AssertionError SoleModels.parsecondition(C, "max[V3} <= 12"; opening_bracket="{", featuretype = SoleModels.AbstractUnivariateFeature)
@test_throws AssertionError SoleModels.parsecondition(C, "max{18] <= 12"; opening_bracket="}", variable_name_prefix = "", featuretype = SoleModels.AbstractUnivariateFeature)
