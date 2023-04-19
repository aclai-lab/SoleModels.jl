using Revise

using Reexport
using FunctionWrappers: FunctionWrapper
using Test
using SoleLogics
using SoleModels
using SoleModels: AbstractModel
using SoleModels: ConstantModel, FinalModel
using SoleModels: LogicalTruthCondition, TrueCondition
using SoleModels: unroll_rules, unroll_rules_cascade, formula, displaymodel, submodels

io = IOBuffer()

################################### FinalModel #############################################
outcome_int =  @test_nowarn ConstantModel(2)
outcome_float = @test_nowarn ConstantModel(1.5)
outcome_string = @test_nowarn ConstantModel("YES")
outcome_string2 = @test_nowarn ConstantModel("NO")

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

cmodels = @test_nowarn [cmodel_string, cmodel_float, cmodel_number, cmodel_integer]
cmodels_num = @test_nowarn [cmodel_float, cmodel_number, cmodel_integer]

@test [cmodel_string, cmodel_float, cmodel_number, cmodel_integer] isa Vector{ConstantModel}
@test_nowarn ConstantModel[cmodel_string, cmodel_float]
@test_throws MethodError ConstantModel{String}[cmodel_string, cmodel_float]
@test_nowarn ConstantModel{Int}[cmodel_number, cmodel_integer]
@test_nowarn ConstantModel{Number}[cmodel_number, cmodel_integer]

##################### String Propositions and SyntaxTree consequent ########################
prop_r = @test_nowarn Proposition("r")
prop_s = @test_nowarn Proposition("s")
prop_t = @test_nowarn Proposition("t")
prop_q = @test_nowarn Proposition("q")

st_r = @test_nowarn SyntaxTree(prop_r)
st_s = @test_nowarn SyntaxTree(prop_s)
st_t = @test_nowarn SyntaxTree(prop_t)
st_q = @test_nowarn SyntaxTree(prop_q)

#################### Integer Propositions and SyntaxTree consequent ########################
prop_1 = @test_nowarn Proposition(1)
prop_100 = @test_nowarn Proposition(100)

##################################### SyntaxTree ###########################################
st_1 = @test_nowarn SyntaxTree(prop_1)
st_100 = @test_nowarn SyntaxTree(prop_100)

################################### Formula ################################################
p = @test_nowarn SoleLogics.parseformula("p")
p_tree = @test_nowarn SoleLogics.parseformulatree("p")

# @test LogicalTruthCondition(p) == LogicalTruthCondition{Formula}(p)
# @test LogicalTruthCondition(p_tree) == LogicalTruthCondition{SyntaxTree}(p_tree)

# phi = @test_nowarn SoleLogics.parseformula("p∧q∨r")
# phi_tree = @test_nowarn SoleLogics.parseformulatree("p∧q∨r")
# @test LogicalTruthCondition(phi) == LogicalTruthCondition{Formula}(phi)
# @test LogicalTruthCondition(phi_tree) == LogicalTruthCondition{SyntaxTree}(phi_tree)

# phi2 = @test_nowarn SoleLogics.parseformula("q∧s→r")
# phi2_tree = @test_nowarn SoleLogics.parseformulatree("q∧s→r")
# @test LogicalTruthCondition(phi2) == LogicalTruthCondition{Formula}(phi2)
# @test LogicalTruthCondition(phi2_tree) == LogicalTruthCondition{SyntaxTree}(phi2_tree)

@test LogicalTruthCondition(p) != LogicalTruthCondition{Formula}(p)
@test LogicalTruthCondition(p_tree) != LogicalTruthCondition{SyntaxTree}(p_tree)

@test LogicalTruthCondition(p) isa LogicalTruthCondition{<:Formula}
@test LogicalTruthCondition(p_tree) isa LogicalTruthCondition{<:SyntaxTree}

phi = @test_nowarn SoleLogics.parseformula("p∧q∨r")
phi_tree = @test_nowarn SoleLogics.parseformulatree("p∧q∨r")
@test LogicalTruthCondition(phi) isa LogicalTruthCondition{<:Formula}
@test LogicalTruthCondition(phi_tree) isa LogicalTruthCondition{<:SyntaxTree}

phi2 = @test_nowarn SoleLogics.parseformula("q∧s→r")
phi2_tree = @test_nowarn SoleLogics.parseformulatree("q∧s→r")
@test LogicalTruthCondition(phi2) isa LogicalTruthCondition{<:Formula}
@test LogicalTruthCondition(phi2_tree) isa LogicalTruthCondition{<:SyntaxTree}

formula_p = @test_nowarn SoleLogics.parseformula("p")
formula_q = @test_nowarn SoleLogics.parseformula("q")
formula_r = @test_nowarn SoleLogics.parseformula("r")
formula_s = @test_nowarn SoleLogics.parseformula("s")

############################### LogicalTruthCondition ######################################
cond_r = @test_nowarn LogicalTruthCondition(st_r)
cond_s = @test_nowarn LogicalTruthCondition(st_s)
cond_t = @test_nowarn LogicalTruthCondition(st_t)
cond_q = @test_nowarn LogicalTruthCondition(st_q)

cond_not_r = @test_nowarn LogicalTruthCondition(¬(formula(cond_r)))
cond_not_s = @test_nowarn LogicalTruthCondition(¬(formula(cond_s)))

cond_1 = @test_nowarn LogicalTruthCondition(st_1)
cond_100 = @test_nowarn LogicalTruthCondition(st_100)

##################################### Rule #################################################
r1_string = @test_nowarn Rule(LogicalTruthCondition(∧(∧(prop_r,prop_s),prop_t)),outcome_string)
r2_string = @test_nowarn Rule(LogicalTruthCondition(¬(prop_r)),outcome_string)

r_true_string = @test_nowarn Rule(outcome_string)
r_true_number = @test_nowarn Rule(cmodel_number)

r1_r2_string = @test_nowarn Rule(LogicalTruthCondition(∧(∧(prop_r,prop_s),prop_t)), r2_string)

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

###################################### DecisionList ########################################
d1_string = @test_nowarn DecisionList([r1_string,r2_string],outcome_string)

rules = @test_nowarn [rmodel_number, rmodel_integer, Rule(phi, cmodel_float), rfloat_number] # , rmodel_bounded_float]
dlmodel = @test_nowarn DecisionList(rules, defaultconsequent)
@test outputtype(dlmodel) == Union{outcometype(defaultconsequent),outcometype.(rules)...}

rules_integer = @test_nowarn [Rule(phi, cmodel_integer), Rule(phi, cmodel_integer)]
dlmodel_integer = @test_nowarn DecisionList(rules_integer, defaultconsequent)
@test outputtype(dlmodel_integer) == Union{outcometype(defaultconsequent),outcometype.(rules_integer)...}

################################## RuleCascade #############################################
rc1_string = @test_nowarn RuleCascade([cond_r,cond_s,cond_t],outcome_string)
rc2_string = @test_nowarn RuleCascade([cond_r],outcome_string)

################################### Branch #################################################
b_nsx = @test_nowarn Branch(cond_q,outcome_string,outcome_string2)
b_fsx = @test_nowarn Branch(cond_s,outcome_string,outcome_string2)
b_fdx = @test_nowarn Branch(cond_t,b_nsx,outcome_string)
b_p = @test_nowarn Branch(cond_r,b_fsx,b_fdx)

bmodel_integer = @test_nowarn Branch(phi, dlmodel_integer, dlmodel_integer)
@test outputtype(bmodel_integer) == Int
bmodel = @test_nowarn Branch(phi, dlmodel_integer, dlmodel)
@test outputtype(bmodel) == Union{outcometype.([dlmodel_integer,dlmodel])...}
@test !isopen(bmodel)

bmodel_mixed = @test_nowarn Branch(phi, rmodel_float, dlmodel_integer)
@test Branch(phi, rmodel_float, dlmodel_integer) isa Branch{Union{Float64,Int}}
bmodel_mixed_number = @test_nowarn Branch(phi, rmodel_number, dlmodel)
@test Branch(phi, rmodel_number, dlmodel) isa Branch{Number}
@test isopen(bmodel_mixed)
@test outputtype(bmodel_mixed) == Union{Nothing,Float64,Int}

@test_nowarn [displaymodel(r) for r in rules];
String(take!(io))
@test_nowarn displaymodel(dlmodel);
String(take!(io))
@test_nowarn displaymodel(bmodel);
String(take!(io))

@test_nowarn Branch(phi,(bmodel,bmodel))
@test_nowarn Branch(phi,(bmodel,rfloat_number))
@test_nowarn Branch(phi,(dlmodel,rmodel_float))
bmodel_2 = @test_nowarn Branch(phi,(dlmodel,bmodel))
@test_nowarn displaymodel(bmodel_2);
String(take!(io))

branch_q = @test_nowarn Branch(formula_q, ("yes", "no"))
branch_s = @test_nowarn Branch(formula_s, ("yes", "no"))
branch_r0 = @test_nowarn Branch(formula_r, (branch_s, "yes"))
branch_r = @test_nowarn Branch(formula_r, (branch_r0, "yes"))
branch_r = @test_nowarn Branch(formula_r, (branch_r, "yes"))

branch_true = @test_nowarn Branch(TrueCondition(), (branch_r, "yes"))

@test typeof(branch_r0) == typeof(branch_r)

rule_r = @test_nowarn Rule(formula_r, branch_r)
rcmodel = RuleCascade([phi,phi,phi], cmodel_integer)
@test_nowarn displaymodel(Branch(phi, rcmodel, bmodel_2));
String(take!(io))

branch_r_mixed = @test_nowarn Branch(formula_r, (rule_r, "no"))

############################### DecisionTree ###############################################
dt1 = @test_nowarn DecisionTree(b_p)
dt2 = @test_nowarn DecisionTree(b_fdx)

dtmodel0 = @test_nowarn DecisionTree("1")
dtmodel = @test_nowarn DecisionTree(branch_r)
#@test_throws AssertionError DecisionTree(branch_r_mixed)

############################## DecisionForest ##############################################
df = @test_nowarn DecisionForest([dt1,dt2])

############################### MixedSymbolicModel #########################################
b_msm = @test_nowarn Branch(cond_q,outcome_int,outcome_float)
dt_msm = @test_nowarn DecisionTree(b_msm)
msm = @test_nowarn MixedSymbolicModel(dt_msm)

msmodel = @test_nowarn MixedSymbolicModel(dtmodel)

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

############################################################################################
#################################### Convert models ########################################
############################################################################################

@test convert(AbstractModel{Int}, cmodel_number) isa AbstractModel{Int}
@test_throws MethodError convert(AbstractModel{<:Int}, cmodel_number)

############################################################################################
############################ Testing immediate_submodels #######################################
############################################################################################

@test_nowarn immediate_submodels(outcome_int)
@test_nowarn immediate_submodels(outcome_float)
@test_nowarn immediate_submodels(outcome_string)
@test_nowarn immediate_submodels(outcome_string2)
@test_nowarn immediate_submodels(cmodel_string)

@test immediate_submodels(outcome_int) isa Vector{Vector{<:AbstractModel{<:Int64}}}
@test immediate_submodels(outcome_float) isa Vector{Vector{<:AbstractModel{<:Float64}}}
@test immediate_submodels(outcome_string) isa Vector{Vector{<:AbstractModel{<:String}}}
@test immediate_submodels(outcome_string2) isa Vector{Vector{<:AbstractModel{<:String}}}
@test immediate_submodels(cmodel_string) isa Vector{Vector{<:AbstractModel{<:String}}}

@test immediate_submodels(r1_string) isa Vector{<:AbstractModel}
@test join(displaymodel.(immediate_submodels(r1_string); header = false)) == """
YES
"""

@test immediate_submodels(r2_string) isa Vector{<:AbstractModel}
@test join(displaymodel.(immediate_submodels(r2_string); header = false)) == """
YES
"""

@test immediate_submodels(rc1_string) isa Vector{<:AbstractModel}
@test join(displaymodel.(immediate_submodels(rc1_string); header = false)) == """
YES
"""

@test immediate_submodels(rcmodel) isa Vector{<:AbstractModel}
@test join(displaymodel.(immediate_submodels(rcmodel); header = false)) == """
1
"""

@test immediate_submodels(b_nsx) isa Vector{<:AbstractModel}
@test immediate_submodels(b_fsx) isa Vector{<:AbstractModel}
@test immediate_submodels(b_fdx) isa Vector{<:AbstractModel}
@test immediate_submodels(b_p) isa Vector{<:AbstractModel}

@test join(displaymodel.(immediate_submodels(b_nsx); header = false)) == """
YES
NO
"""

@test join(displaymodel.(immediate_submodels(b_fsx); header = false)) == """
YES
NO
"""

@test join(displaymodel.(immediate_submodels(b_fdx); header = false)) == """
┐ q
├ ✔ YES
└ ✘ NO
YES
"""

@test join(displaymodel.(immediate_submodels(b_p); header = false)) == """
┐ s
├ ✔ YES
└ ✘ NO
┐ t
├ ✔ ┐ q
│   ├ ✔ YES
│   └ ✘ NO
└ ✘ YES
"""

@test immediate_submodels(d1_string) isa Vector{<:AbstractModel}
@test join(displaymodel.(immediate_submodels(d1_string); header = false)) == """
┐(r ∧ s) ∧ t
└ ✔ YES
┐¬(r)
└ ✔ YES
YES
"""

@test immediate_submodels(dt1) isa Vector{<:AbstractModel}
@test join(displaymodel.(immediate_submodels(dt1); header = false)) == """
┐ s
├ ✔ YES
└ ✘ NO
┐ t
├ ✔ ┐ q
│   ├ ✔ YES
│   └ ✘ NO
└ ✘ YES
"""

@test immediate_submodels(dt2) isa Vector{<:AbstractModel}
@test join(displaymodel.(immediate_submodels(dt2); header = false)) == """
┐ q
├ ✔ YES
└ ✘ NO
YES
"""

@test immediate_submodels(msm) isa Vector{<:AbstractModel}
@test join(displaymodel.(immediate_submodels(msm); header = false)) == """
2
1.5
"""

############################################################################################
################################ Testing submodels #########################################
############################################################################################

@test_nowarn submodels(outcome_int)
@test_nowarn submodels(outcome_float)
@test_nowarn submodels(outcome_string)
@test_nowarn submodels(outcome_string2)
@test_nowarn submodels(cmodel_string)

@test submodels(outcome_int) isa Vector{Any}
@test submodels(outcome_float) isa Vector{Any}
@test submodels(outcome_string) isa Vector{Any}
@test submodels(outcome_string2) isa Vector{Any}
@test submodels(cmodel_string) isa Vector{Any}

@test submodels(r1_string) isa Vector{<:AbstractModel}
@test join(displaymodel.(submodels(r1_string); header = false)) == """
YES
"""

@test submodels(r2_string) isa Vector{<:AbstractModel}
@test join(displaymodel.(submodels(r2_string); header = false)) == """
YES
"""

@test submodels(rc1_string) isa Vector{<:AbstractModel}
@test join(displaymodel.(submodels(rc1_string); header = false)) == """
YES
"""

@test submodels(rcmodel) isa Vector{<:AbstractModel}
@test join(displaymodel.(submodels(rcmodel); header = false)) == """
1
"""

@test submodels(b_nsx) isa Vector{<:AbstractModel}
@test submodels(b_fsx) isa Vector{<:AbstractModel}
@test submodels(b_fdx) isa Vector{<:AbstractModel}
@test submodels(b_p) isa Vector{<:AbstractModel}

@test join(displaymodel.(submodels(b_nsx); header = false)) == """
YES
NO
"""

@test join(displaymodel.(submodels(b_fsx); header = false)) == """
YES
NO
"""

@test join(displaymodel.(submodels(b_fdx); header = false)) == """
┐ q
├ ✔ YES
└ ✘ NO
YES
NO
YES
"""

@test join(displaymodel.(submodels(b_p); header = false)) == """
┐ s
├ ✔ YES
└ ✘ NO
YES
NO
┐ t
├ ✔ ┐ q
│   ├ ✔ YES
│   └ ✘ NO
└ ✘ YES
┐ q
├ ✔ YES
└ ✘ NO
YES
NO
YES
"""

@test submodels(d1_string) isa Vector{<:AbstractModel}
@test join(displaymodel.(submodels(d1_string); header = false)) == """
┐(r ∧ s) ∧ t
└ ✔ YES
YES
┐¬(r)
└ ✔ YES
YES
YES
"""

@test submodels(dt1) isa Vector{<:AbstractModel}
@test join(displaymodel.(submodels(dt1); header = false)) == """
┐ s
├ ✔ YES
└ ✘ NO
YES
NO
┐ t
├ ✔ ┐ q
│   ├ ✔ YES
│   └ ✘ NO
└ ✘ YES
┐ q
├ ✔ YES
└ ✘ NO
YES
NO
YES
"""

@test submodels(dt2) isa Vector{<:AbstractModel}
@test join(displaymodel.(submodels(dt2); header = false)) == """
┐ q
├ ✔ YES
└ ✘ NO
YES
NO
YES
"""

@test submodels(msm) isa Vector{<:AbstractModel}
@test join(displaymodel.(submodels(msm); header = false)) == """
2
1.5
"""

############################################################################################
###################### Testing unroll_rules_cascade ########################################
############################################################################################

@test_nowarn unroll_rules_cascade(outcome_int)
@test_nowarn unroll_rules_cascade(outcome_float)
@test_nowarn unroll_rules_cascade(outcome_string)
@test_nowarn unroll_rules_cascade(outcome_string2)
@test_nowarn unroll_rules_cascade(cmodel_string)

@test unroll_rules_cascade(outcome_int) isa Vector{<:ConstantModel}
@test unroll_rules_cascade(outcome_float) isa Vector{<:ConstantModel}
@test unroll_rules_cascade(outcome_string) isa Vector{<:ConstantModel}
@test unroll_rules_cascade(outcome_string2) isa Vector{<:ConstantModel}
@test unroll_rules_cascade(cmodel_string) isa Vector{<:ConstantModel}

@test unroll_rules_cascade(r1_string) isa Vector{<:RuleCascade}
@test join(displaymodel.(unroll_rules_cascade(r1_string); header = false)) == """
┐⩚((r ∧ s) ∧ t)
└ ✔ YES
"""

@test unroll_rules_cascade(r2_string) isa Vector{<:RuleCascade}
@test join(displaymodel.(unroll_rules_cascade(r2_string); header = false)) == """
┐⩚(¬(r))
└ ✔ YES
"""

@test unroll_rules_cascade(rc1_string) isa Vector{<:RuleCascade}
@test join(displaymodel.(unroll_rules_cascade(rc1_string); header = false)) == """
┐⩚(r, s, t)
└ ✔ YES
"""

@test unroll_rules_cascade(rcmodel) isa Vector{<:RuleCascade}
@test join(displaymodel.(unroll_rules_cascade(rcmodel); header = false)) == """
┐⩚(p ∧ (q ∨ r), p ∧ (q ∨ r), p ∧ (q ∨ r))
└ ✔ 1
"""

@test unroll_rules_cascade(b_nsx) isa Vector{<:RuleCascade}
@test unroll_rules_cascade(b_fsx) isa Vector{<:RuleCascade}
@test unroll_rules_cascade(b_fdx) isa Vector{<:RuleCascade}
@test unroll_rules_cascade(b_p) isa Vector{<:RuleCascade}

@test join(displaymodel.(unroll_rules_cascade(b_nsx); header = false)) == """
┐⩚(q)
└ ✔ YES
┐⩚(¬(q))
└ ✔ NO
"""

@test join(displaymodel.(unroll_rules_cascade(b_fsx); header = false)) == """
┐⩚(s)
└ ✔ YES
┐⩚(¬(s))
└ ✔ NO
"""

@test join(displaymodel.(unroll_rules_cascade(b_fdx); header = false)) == """
┐⩚(t, q)
└ ✔ YES
┐⩚(t, ¬(q))
└ ✔ NO
┐⩚(¬(t))
└ ✔ YES
"""
# [{t,q} => YES, {t,¬q} => NO, {¬t} => YES]"

@test join(displaymodel.(unroll_rules_cascade(b_p); header = false)) == """
┐⩚(r, s)
└ ✔ YES
┐⩚(r, ¬(s))
└ ✔ NO
┐⩚(¬(r), t, q)
└ ✔ YES
┐⩚(¬(r), t, ¬(q))
└ ✔ NO
┐⩚(¬(r), ¬(t))
└ ✔ YES
"""

@test unroll_rules_cascade(d1_string) isa Vector{<:RuleCascade}
@test join(displaymodel.(unroll_rules_cascade(d1_string); header = false)) == """
┐⩚((r ∧ s) ∧ t)
└ ✔ YES
┐⩚(¬(r))
└ ✔ YES
┐⩚(⊤)
└ ✔ YES
"""

@test unroll_rules_cascade(dt1) isa Vector{<:RuleCascade}
@test join(displaymodel.(unroll_rules_cascade(dt1); header = false)) == """
┐⩚(r, s)
└ ✔ YES
┐⩚(r, ¬(s))
└ ✔ NO
┐⩚(¬(r), t, q)
└ ✔ YES
┐⩚(¬(r), t, ¬(q))
└ ✔ NO
┐⩚(¬(r), ¬(t))
└ ✔ YES
"""

@test unroll_rules_cascade(dt2) isa Vector{<:RuleCascade}
@test join(displaymodel.(unroll_rules_cascade(dt2); header = false)) == """
┐⩚(t, q)
└ ✔ YES
┐⩚(t, ¬(q))
└ ✔ NO
┐⩚(¬(t))
└ ✔ YES
"""

@test unroll_rules_cascade(msm) isa Vector{<:RuleCascade}
@test join(displaymodel.(unroll_rules_cascade(msm); header = false)) == """
┐⩚(q)
└ ✔ 2
┐⩚(¬(q))
└ ✔ 1.5
"""

#=
unroll_rules_cascade(rule_r)
unroll_rules_cascade(branch_r)
=#

############################################################################################
############################ Testing unroll_rules ##########################################
############################################################################################

@test_nowarn unroll_rules(outcome_int)
@test_nowarn unroll_rules(outcome_float)
@test_nowarn unroll_rules(outcome_string)
@test_nowarn unroll_rules(outcome_string2)
@test_nowarn unroll_rules(cmodel_string)

@test unroll_rules(outcome_int) isa Vector{<:ConstantModel}
@test unroll_rules(outcome_float) isa Vector{<:ConstantModel}
@test unroll_rules(outcome_string) isa Vector{<:ConstantModel}
@test unroll_rules(outcome_string2) isa Vector{<:ConstantModel}
@test unroll_rules(cmodel_string) isa Vector{<:ConstantModel}


@test_nowarn unroll_rules(rule_r)
@test_nowarn ruleset = unroll_rules(branch_r)
@test_broken unroll_rules(dlmodel)
@test_nowarn unroll_rules(rcmodel)

@test_nowarn unroll_rules_cascade(cmodel_string)
#@test_nowarn unroll_rules_cascade(rule_r)
#@test_nowarn unroll_rules_cascade(branch_r)
#@test_nowarn unroll_rules_cascade(dlmodel)
#@test_nowarn unroll_rules_cascade(rcmodel)

#unroll_rules_cascade.([rfloat_number, dlmodel, dlmodel_integer, bmodel_integer, bmodel, bmodel_mixed, bmodel_mixed_number, dtmodel0, dtmodel, ms_model])


@test unroll_rules(r1_string) isa Vector{<:Rule}
@test join(displaymodel.(unroll_rules(r1_string); header = false)) == """
┐(r ∧ s) ∧ t
└ ✔ YES
"""

@test unroll_rules(r2_string) isa Vector{<:Rule}
@test join(displaymodel.(unroll_rules(r2_string); header = false)) == """
┐¬(r)
└ ✔ YES
"""

@test unroll_rules(d1_string) isa Vector{<:Rule}
@test join(displaymodel.(unroll_rules(d1_string); header = false)) == """
┐(r ∧ s) ∧ t
└ ✔ YES
┐¬(r)
└ ✔ YES
┐⊤
└ ✔ YES
"""

@test unroll_rules(rc1_string) isa Vector{<:Rule}
@test join(displaymodel.(unroll_rules(rc1_string); header = false)) == """
┐r ∧ (s ∧ t)
└ ✔ YES
"""

@test unroll_rules(rcmodel) isa Vector{<:Rule}
@test join(displaymodel.(unroll_rules(rcmodel); header = false)) == """
┐(p ∧ (q ∨ r)) ∧ ((p ∧ (q ∨ r)) ∧ (p ∧ (q ∨ r)))
└ ✔ 1
"""

@test unroll_rules(b_nsx) isa Vector{<:Rule}
@test join(displaymodel.(unroll_rules(b_nsx); header = false)) == """
┐q
└ ✔ YES
┐¬(q)
└ ✔ NO
"""

@test unroll_rules(b_fsx) isa Vector{<:Rule}
@test join(displaymodel.(unroll_rules(b_fsx); header = false)) == """
┐s
└ ✔ YES
┐¬(s)
└ ✔ NO
"""

@test unroll_rules(b_fdx) isa Vector{<:Rule}
@test join(displaymodel.(unroll_rules(b_fdx); header = false)) == """
┐t ∧ q
└ ✔ YES
┐t ∧ (¬(q))
└ ✔ NO
┐¬(t)
└ ✔ YES
"""

@test unroll_rules(b_p) isa Vector{<:Rule}
@test join(displaymodel.(unroll_rules(b_p); header = false)) == """
┐r ∧ s
└ ✔ YES
┐r ∧ (¬(s))
└ ✔ NO
┐(¬(r)) ∧ (t ∧ q)
└ ✔ YES
┐(¬(r)) ∧ (t ∧ (¬(q)))
└ ✔ NO
┐(¬(r)) ∧ (¬(t))
└ ✔ YES
"""

@test unroll_rules(dt1) isa Vector{<:Rule}
@test join(displaymodel.(unroll_rules(dt1); header = false)) == """
┐r ∧ s
└ ✔ YES
┐r ∧ (¬(s))
└ ✔ NO
┐(¬(r)) ∧ (t ∧ q)
└ ✔ YES
┐(¬(r)) ∧ (t ∧ (¬(q)))
└ ✔ NO
┐(¬(r)) ∧ (¬(t))
└ ✔ YES
"""

@test unroll_rules(dt2) isa Vector{<:Rule}
@test join(displaymodel.(unroll_rules(dt2); header = false)) == """
┐t ∧ q
└ ✔ YES
┐t ∧ (¬(q))
└ ✔ NO
┐¬(t)
└ ✔ YES
"""

@test unroll_rules(msm) isa Vector{<:Rule}
@test join(displaymodel.(unroll_rules(msm); header = false)) == """
┐q
└ ✔ 2
┐¬(q)
└ ✔ 1.5
"""

############################################################################################
############################### Testing convert ############################################
############################################################################################

@test convert(Rule,rc1_string) isa Rule
@test convert(Rule,rc2_string) isa Rule

@test convert(Rule, rcmodel) isa Rule

#=
@test convert(RuleCascade,r1_string) isa RuleCascade
displaymodel.(io,convert(RuleCascade,r1_string))
@test String(take!(io)) == """
RuleCascade{String, LogicalTruthCondition{SyntaxTree{SoleLogics.NamedOperator{:∧}}}, ConstantModel{String}}
┐⩚(r ∧ s ∧ t)
└ ✔ YES
"""
@test_nowarn convert(RuleCascade,r2_string)
displaymodel.(io,convert(RuleCascade,r2_string))
@test String(take!(io)) == """
RuleCascade{String, LogicalTruthCondition{SyntaxTree{Proposition{String}}, SoleLogics.NamedOperator{:¬}}}, ConstantModel{String}}
┐⩚(¬(r))
└ ✔ YES
"""
=#
