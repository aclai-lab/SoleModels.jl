using SoleModels
using SoleLogics
using FunctionWrappers: FunctionWrapper
using SoleModels: AbstractModel
using SoleModels: ConstantModel, FinalModel
using SoleModels: ConstrainedModel, check_model_constraints
using Test

# base.jl

io = IOBuffer()

p = SoleLogics.parseformula("p")
phi = SoleLogics.parseformula("p∧q∨r")
phi2 = SoleLogics.parseformula("q∧s→r")

formula_p = SoleLogics.parseformula("p")
formula_q = SoleLogics.parseformula("q")
formula_r = SoleLogics.parseformula("r")
formula_s = SoleLogics.parseformula("s")

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Final models ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

@test_nowarn ConstantModel(1,(;))
@test_nowarn ConstantModel(1)
@test_throws MethodError ConstantModel{Float64}(1,(;))

const_string = "Wow!"
const_float = 1.0
const_integer = 1
const_fun = sum
const_funwrap = FunctionWrapper{Float64, Tuple{Float64,Float64}}(sum)

consts = @test_nowarn [const_string, const_float, const_integer, const_funwrap]

@test (@test_logs (:warn,) SoleModels.wrap(const_fun) isa SoleModels.FunctionModel{Any})
@test_nowarn SoleModels.wrap.(consts)
@test_nowarn ConstantModel{String}(const_string)
cmodel_string = @test_nowarn ConstantModel(const_string)
@test cmodel_string isa ConstantModel{String}
cmodel_float = @test_nowarn ConstantModel{Float64}(const_float)
cmodel_number = @test_nowarn ConstantModel{Number}(const_integer)
cmodel_integer = @test_nowarn ConstantModel{Int}(const_integer)

@test (@test_logs (:warn,) SoleModels.FunctionModel{Int}(const_fun)) isa SoleModels.FunctionModel{Int}

cmodels = @test_nowarn [cmodel_string, cmodel_float, cmodel_number, cmodel_integer]
cmodels_num = @test_nowarn [cmodel_float, cmodel_number, cmodel_integer]

@test [cmodel_string, cmodel_float, cmodel_number, cmodel_integer] isa Vector{ConstantModel}
@test_nowarn ConstantModel[cmodel_string, cmodel_float]
@test_throws MethodError ConstantModel{String}[cmodel_string, cmodel_float]
@test_nowarn ConstantModel{Int}[cmodel_number, cmodel_integer]
@test_nowarn ConstantModel{Number}[cmodel_number, cmodel_integer]

@test convert(AbstractModel{Int}, cmodel_number) isa AbstractModel{Int}
@test_throws MethodError convert(AbstractModel{<:Int}, cmodel_number)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Rules ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

rmodel_number = @test_nowarn Rule(phi, cmodel_number)
rmodel_integer = @test_nowarn Rule(phi, cmodel_integer)

@test rmodel_number isa Rule{Number}
@test rmodel_integer isa Rule{Int}
@test Rule{Int}(phi, cmodel_number) isa Rule{Int}
@test Rule{Int}(phi, cmodel_integer) isa Rule{Int}
@test Rule{Number}(phi, cmodel_integer) isa Rule{Number}
@test Rule{Number}(phi, cmodel_number) isa Rule{Number}

@test_nowarn [Rule(phi, c) for c in consts]
@test_nowarn [Rule(phi, c) for c in cmodels]

@test_nowarn Rule{Float64}(phi,const_float)
# @test_nowarn Rule{Float64,Union{Rule,ConstantModel}}(phi,const_float)
rmodel_float0 = @test_nowarn Rule{Float64}(phi,const_float)
rmodel_float = @test_nowarn Rule{Float64}(phi,rmodel_float0)
rmodel_float2 = @test_nowarn Rule{Float64}(phi,rmodel_float)
@test typeof(rmodel_float2) == typeof(rmodel_float)
# @test typeof(rmodel_float) == typeof(Rule{Float64,Union{Rule{Float64},ConstantModel{Float64}}}(phi,rmodel_float0))
# @test typeof(rmodel_float) != typeof(Rule{Float64,Union{Rule{Float64},FinalModel{Float64}}}(phi,rmodel_float0))
# @test typeof(rmodel_float) == typeof(Rule{Float64,Union{Rule,ConstantModel}}(phi,rmodel_float0))

rmodel2_float = @test_nowarn Rule(phi2, rmodel_float)

@test_nowarn [Rule{<:Any}(phi, c) for c in cmodels]
@test_nowarn [Rule{Number}(phi, c) for c in cmodels_num]
@test_nowarn [Rule{Number}(phi, c) for c in cmodels_num]

rmodel3 = @test_nowarn Rule{Number}(phi,1)
# rmodel4 = @test_nowarn Rule{Number,ConstantModel{Number}}(phi, 1)
# @test_nowarn [rmodel3, rmodel4]

# rmodel3 = @test_nowarn Rule{Number,ConstantModel{Number}}(phi,1)
@test rmodel3 isa Rule{Number,<:Any,Union{ConstantModel{Number}}}
# @test Rule{Number,ConstantModel{Int}}(phi, 1) isa Rule{Number, Union{ConstantModel{Number}}}
# @test Rule{Int,ConstantModel{Number}}(phi, 1) isa Rule{Int, Union{ConstantModel{Int}}}
# @test_throws MethodError Rule{Int,<:Any,ConstantModel{Number}}(phi, 1.0)

# @test rmodel3 == Rule{Number,Union{Rule{Int},ConstantModel{Number}}}(phi,1)
# @test rmodel3 != Rule{Number,Union{Rule{Number},ConstantModel{Int}}}(phi,1)

# @test_nowarn Rule{Number,ConstantModel{<:Number}}(phi,1)
# @test_nowarn Rule{Number,Union{ConstantModel{Int},ConstantModel{Float64}}}(phi,1)

# rfloat_number = @test_nowarn Rule{Float64,Union{Rule{Float64},ConstantModel{Float64}}}(phi,1.0)
rfloat_number = @test_nowarn Rule{Float64}(phi,1.0)

# @test_broken Rule{Number,Union{Rule{Number},ConstantModel{Number}}}(phi, rfloat_number)
# r = @test_nowarn Rule{Number,Union{Rule{Number},ConstantModel{Number}}}(phi,rmodel3)
# r = @test_nowarn Rule{Number,Union{Rule{Number},ConstantModel{Number}}}(phi,r)
# r = @test_nowarn Rule{Number,Union{Rule{Number},ConstantModel{Number}}}(phi,r)

rfloat_number0 = @test_nowarn Rule{Number}(phi,rmodel3)
rfloat_number = @test_nowarn Rule{Number}(phi,rfloat_number0)
rfloat_number = @test_nowarn Rule{Number}(phi,rfloat_number)
rfloat_number = @test_nowarn Rule{Number}(phi,rfloat_number)
rfloat_number = @test_nowarn Rule{Number}(phi,rfloat_number)

@test typeof(rfloat_number0) == typeof(rfloat_number)

@test outcometype(rfloat_number) == Number
@test outputtype(rfloat_number) == Union{Nothing,Number}


defaultconsequent = cmodel_integer

# rmodel_bounded_float = @test_nowarn Rule{Float64,Union{Rule{Float64},ConstantModel{Float64}}}(phi,Rule{Float64,Union{Rule{Float64},ConstantModel{Float64}}}(phi,cmodel_float))

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Other models ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

rules = @test_nowarn [rmodel_number, rmodel_integer, Rule(phi, cmodel_float), rfloat_number] # , rmodel_bounded_float]
dlmodel = @test_nowarn DecisionList(rules, defaultconsequent)
@test outputtype(dlmodel) == Union{outcometype(defaultconsequent),outcometype.(rules)...}

rules_integer = @test_nowarn [Rule(phi, cmodel_integer), Rule(phi, cmodel_integer)]
dlmodel_integer = @test_nowarn DecisionList(rules_integer, defaultconsequent)
@test outputtype(dlmodel_integer) == Union{outcometype(defaultconsequent),outcometype.(rules_integer)...}

bmodel_integer = @test_nowarn Branch(phi, dlmodel_integer, dlmodel_integer)
@test outputtype(bmodel_integer) == Int
bmodel = @test_nowarn Branch(phi, dlmodel_integer, dlmodel)
@test outputtype(bmodel) == Union{outcometype.([dlmodel_integer, dlmodel])...}
@test !isopen(bmodel)

bmodel_mixed = @test_nowarn Branch(phi, rmodel_float, dlmodel_integer)
@test Branch(phi, rmodel_float, dlmodel_integer) isa Branch{Union{Float64,Int}}
bmodel_mixed_number = @test_nowarn Branch(phi, rmodel_number, dlmodel)
@test Branch(phi, rmodel_number, dlmodel) isa Branch{Number}
@test isopen(bmodel_mixed)
@test outputtype(bmodel_mixed) == Union{Nothing,Float64,Int}

@test_nowarn [printmodel(io, r) for r in rules];
@test_nowarn printmodel(io, dlmodel);
@test_nowarn printmodel(io, bmodel);

@test_nowarn Branch(phi,(bmodel,bmodel))
@test_nowarn Branch(phi,(bmodel,rfloat_number))
@test_nowarn Branch(phi,(dlmodel,rmodel_float))
bmodel_2 = @test_nowarn Branch(phi,(dlmodel,bmodel))
@test_nowarn printmodel(io, bmodel_2);

rcmodel = RuleCascade([phi,phi,phi], cmodel_integer)
@test_nowarn printmodel(io, Branch(phi, rcmodel, bmodel_2));


branch_q = @test_nowarn Branch(formula_q, ("yes", "no"))
branch_s = @test_nowarn Branch(formula_s, ("yes", "no"))
branch_r0 = @test_nowarn Branch(formula_r, (branch_s, "yes"))
branch_r = @test_nowarn Branch(formula_r, (branch_r0, "yes"))
branch_r = @test_nowarn Branch(formula_r, (branch_r, "yes"))

@test typeof(branch_r0) == typeof(branch_r)

rule_r = @test_nowarn Rule(formula_r, branch_r)
branch_r_mixed = @test_nowarn Branch(formula_r, (rule_r, "no"))

dtmodel0 = @test_nowarn DecisionTree("1")
dtmodel = @test_nowarn DecisionTree(branch_r)
@test_throws AssertionError DecisionTree(branch_r_mixed)
# msmodel = MixedSymbolicModel(dtmodel)

complex_mixed_model = @test_nowarn Branch(formula_r, (dtmodel, dlmodel))

@test_nowarn MixedSymbolicModel("1")
@test_nowarn MixedSymbolicModel(const_funwrap)
@test_nowarn MixedSymbolicModel(dtmodel)
@test_nowarn MixedSymbolicModel(dlmodel)
ms_model0 = MixedSymbolicModel(complex_mixed_model)

MixedSymbolicModel(MixedSymbolicModel("1"))
MixedSymbolicModel(MixedSymbolicModel(complex_mixed_model))
MixedSymbolicModel(MixedSymbolicModel(MixedSymbolicModel(complex_mixed_model)))
ms_model1 = MixedSymbolicModel(ms_model0)
ms_model = MixedSymbolicModel(ms_model1)
ms_model = MixedSymbolicModel(ms_model)
ms_model = MixedSymbolicModel(ms_model)

@test typeof(ms_model1) == typeof(ms_model)
