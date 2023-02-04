using Revise

using Reexport
using FunctionWrappers
using FunctionWrappers: FunctionWrapper
using Base
using Test
using SoleLogics
using SoleLogics: Proposition, SyntaxTree, ¬, ∧, ⊤, AbstractLogic
using SoleModels
using SoleModels: FormulaOrTree, ConstantModel, FinalModel, LogicalTruthCondition
using SoleModels: ConstrainedModel, check_model_constraints
using SoleModels: DecisionForest, DecisionList, DecisionTree, Branch
using SoleModels: Rule, RuleCascade, AbstractBooleanCondition
using SoleModels: unroll_rules, unroll_rules_cascade, formula, root

#Sostituto di SoleLogics.TOP
# const TOP = SoleLogics.parseformula("⊤")
################################### IOBuffer ###############################################
io = @test_nowarn IOBuffer()

################################### FinalModel #############################################
outcome_int =  @test_nowarn ConstantModel(2)
outcome_float = @test_nowarn ConstantModel(1.5)
outcome_string = @test_nowarn ConstantModel("true")
outcome_string2 = @test_nowarn ConstantModel("false")

@test_nowarn ConstantModel(1,(;))
@test_nowarn ConstantModel(1)
@test_throws MethodError ConstantModel{Float64}(1,(;))

const_string = "Wow!"
const_float = 1.0
const_integer = 1
const_fun = sum
const_funwrap = FunctionWrapper{Float64, Tuple{Float64, Float64}}(sum)

consts = @test_nowarn [const_string, const_float, const_integer, const_funwrap]

# @test SoleModels.wrap(const_fun) isa SoleModels.FunctionModel{Any}
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
@test LogicalTruthCondition(p) == LogicalTruthCondition{Formula}(p)
@test LogicalTruthCondition(p_tree) == LogicalTruthCondition{SyntaxTree}(p_tree)

phi = @test_nowarn SoleLogics.parseformula("p∧q∨r")
phi_tree = @test_nowarn SoleLogics.parseformulatree("p∧q∨r")
@test LogicalTruthCondition(phi) == LogicalTruthCondition{Formula}(phi)
@test LogicalTruthCondition(phi_tree) == LogicalTruthCondition{SyntaxTree}(phi_tree)

phi2 = @test_nowarn SoleLogics.parseformula("q∧s→r")
phi2_tree = @test_nowarn SoleLogics.parseformulatree("q∧s→r")
@test LogicalTruthCondition(phi2) == LogicalTruthCondition{Formula}(phi2)
@test LogicalTruthCondition(phi2_tree) == LogicalTruthCondition{SyntaxTree}(phi2_tree)

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
# @test_nowarn Rule{Float64,Union{Rule, ConstantModel}}(phi,const_float)
rmodel_float0 = @test_nowarn Rule{Float64}(phi,const_float)
rmodel_float = @test_nowarn Rule{Float64}(phi,rmodel_float0)
rmodel_float2 = @test_nowarn Rule{Float64}(phi,rmodel_float)
@test typeof(rmodel_float2) == typeof(rmodel_float)
# @test typeof(rmodel_float) == typeof(Rule{Float64,Union{Rule{Float64},ConstantModel{Float64}}}(phi,rmodel_float0))
# @test typeof(rmodel_float) != typeof(Rule{Float64,Union{Rule{Float64},FinalModel{Float64}}}(phi,rmodel_float0))
# @test typeof(rmodel_float) == typeof(Rule{Float64,Union{Rule, ConstantModel}}(phi,rmodel_float0))

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
@test output_type(rfloat_number) == Union{Nothing, Number}


default_consequent = cmodel_integer

# rmodel_bounded_float = @test_nowarn Rule{Float64,Union{Rule{Float64},ConstantModel{Float64}}}(phi,Rule{Float64,Union{Rule{Float64},ConstantModel{Float64}}}(phi,cmodel_float))

###################################### DecisionList ########################################
d1_string = @test_nowarn DecisionList([r1_string,r2_string],outcome_string)

rules = @test_nowarn [rmodel_number, rmodel_integer, Rule(phi, cmodel_float), rfloat_number] # , rmodel_bounded_float]
dlmodel = @test_nowarn DecisionList(rules, default_consequent)
@test output_type(dlmodel) == Union{outcometype(default_consequent),outcometype.(rules)...}

rules_integer = @test_nowarn [Rule(phi, cmodel_integer), Rule(phi, cmodel_integer)]
dlmodel_integer = @test_nowarn DecisionList(rules_integer, default_consequent)
@test output_type(dlmodel_integer) == Union{outcometype(default_consequent),outcometype.(rules_integer)...}

################################## RuleCascade #############################################
rc1_string = @test_nowarn RuleCascade([cond_r,cond_s,cond_t],outcome_string)
rc2_string = @test_nowarn RuleCascade([cond_r],outcome_string)

################################### Branch #################################################
b_nsx = @test_nowarn Branch(cond_q,outcome_string,outcome_string2)
b_fsx = @test_nowarn Branch(cond_s,outcome_string,outcome_string2)
b_fdx = @test_nowarn Branch(cond_t,b_nsx,outcome_string)
b_p = @test_nowarn Branch(cond_r,b_fsx,b_fdx)

bmodel_integer = @test_nowarn Branch(phi, dlmodel_integer, dlmodel_integer)
@test output_type(bmodel_integer) == Int
bmodel = @test_nowarn Branch(phi, dlmodel_integer, dlmodel)
@test output_type(bmodel) == Union{outcometype.([dlmodel_integer, dlmodel])...}
@test !isopen(bmodel)

bmodel_mixed = @test_nowarn Branch(phi, rmodel_float, dlmodel_integer)
@test Branch(phi, rmodel_float, dlmodel_integer) isa Branch{Union{Float64,Int}}
bmodel_mixed_number = @test_nowarn Branch(phi, rmodel_number, dlmodel)
@test Branch(phi, rmodel_number, dlmodel) isa Branch{Number}
@test isopen(bmodel_mixed)
@test output_type(bmodel_mixed) == Union{Nothing,Float64,Int}

@test_nowarn [print_model(io, r) for r in rules];
String(take!(io))
@test_nowarn print_model(io, dlmodel);
String(take!(io))
@test_nowarn print_model(io, bmodel);
String(take!(io))

@test_nowarn Branch(phi,(bmodel,bmodel))
@test_nowarn Branch(phi,(bmodel,rfloat_number))
@test_nowarn Branch(phi,(dlmodel,rmodel_float))
bmodel_2 = @test_nowarn Branch(phi,(dlmodel,bmodel))
@test_nowarn print_model(io, bmodel_2);
String(take!(io))

branch_q = @test_nowarn Branch(formula_q, ("yes", "no"))
branch_s = @test_nowarn Branch(formula_s, ("yes", "no"))
branch_r0 = @test_nowarn Branch(formula_r, (branch_s, "yes"))
branch_r = @test_nowarn Branch(formula_r, (branch_r0, "yes"))
branch_r = @test_nowarn Branch(formula_r, (branch_r, "yes"))

@test typeof(branch_r0) == typeof(branch_r)

rule_r = @test_nowarn Rule(formula_r, branch_r)
rcmodel = RuleCascade([phi,phi,phi], cmodel_integer)
@test_nowarn print_model(io, Branch(phi, rcmodel, bmodel_2));
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
b_msm = @test_nowarn Branch(cond_q,dt1,r1_r2_string)
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
print_model(io,unroll_rules_cascade(r1_string))
@test String(take!(io)) == """
1-element Vector{RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}}
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(r ∧ s ∧ t)
└ ✔ true
"""

@test unroll_rules_cascade(r2_string) isa Vector{<:RuleCascade}
print_model(io,unroll_rules_cascade(r2_string))
@test String(take!(io)) == """
1-element Vector{RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}}
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(¬(r))
└ ✔ true
"""

@test unroll_rules_cascade(rc1_string) isa Vector{<:RuleCascade}
print_model(io,unroll_rules_cascade(rc1_string))
@test String(take!(io)) == """
1-element Vector{RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}}
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(r, s, t)
└ ✔ true
"""

@test unroll_rules_cascade(rcmodel) isa Vector{<:RuleCascade}
print_model(io,unroll_rules_cascade(rcmodel))
@test String(take!(io)) == """
1-element Vector{RuleCascade{Int64, LogicalTruthCondition{Formula}, ConstantModel{Int64}}}
RuleCascade{Int64, LogicalTruthCondition{Formula}, ConstantModel{Int64}}
┐⩚(p ∧ q ∧ r, p ∧ q ∧ r, p ∧ q ∧ r)
└ ✔ 1
"""

@test unroll_rules_cascade(b_nsx) isa Vector{<:RuleCascade}
@test unroll_rules_cascade(b_fsx) isa Vector{<:RuleCascade}
@test unroll_rules_cascade(b_fdx) isa Vector{<:RuleCascade}
@test unroll_rules_cascade(b_p) isa Vector{<:RuleCascade}

print_model(io,unroll_rules_cascade(b_nsx))
@test String(take!(io)) == """
2-element Vector{RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}}
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(q)
└ ✔ true
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(¬(q))
└ ✔ false
"""

print_model(io,unroll_rules_cascade(b_fsx))
@test String(take!(io)) == """
2-element Vector{RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}}
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(s)
└ ✔ true
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(¬(s))
└ ✔ false
"""

print_model(io,unroll_rules_cascade(b_fdx))
@test String(take!(io)) == """
3-element Vector{RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}}
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(t, q)
└ ✔ true
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(t, ¬(q))
└ ✔ false
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(¬(t))
└ ✔ true
"""
# [{t, q} => true, {t, ¬q} => false, {¬t} => true]"

print_model(io,unroll_rules_cascade(b_p))
@test String(take!(io)) == """
5-element Vector{RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}}
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(r, s)
└ ✔ true
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(r, ¬(s))
└ ✔ false
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(¬(r), t, q)
└ ✔ true
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(¬(r), t, ¬(q))
└ ✔ false
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(¬(r), ¬(t))
└ ✔ true
"""

@test unroll_rules_cascade(d1_string) isa Vector{<:RuleCascade}
print_model(io,unroll_rules_cascade(d1_string))
@test String(take!(io)) == """
3-element Vector{RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}}
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(r ∧ s ∧ t)
└ ✔ true
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(¬(r))
└ ✔ true
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(⊤)
└ ✔ true
"""

@test unroll_rules_cascade(dt1) isa Vector{<:RuleCascade}
print_model(io,unroll_rules_cascade(dt1))
@test String(take!(io)) == """
5-element Vector{RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}}
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(r, s)
└ ✔ true
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(r, ¬(s))
└ ✔ false
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(¬(r), t, q)
└ ✔ true
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(¬(r), t, ¬(q))
└ ✔ false
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(¬(r), ¬(t))
└ ✔ true
"""

@test unroll_rules_cascade(dt2) isa Vector{<:RuleCascade}
print_model(io,unroll_rules_cascade(dt2))
@test String(take!(io)) == """
3-element Vector{RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}}
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(t, q)
└ ✔ true
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(t, ¬(q))
└ ✔ false
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(¬(t))
└ ✔ true
"""

@test unroll_rules_cascade(msm) isa Vector{<:RuleCascade}
print_model(io,unroll_rules_cascade(msm))
@test String(take!(io)) == """
6-element Vector{RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}}
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(q, r, s)
└ ✔ true
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(q, r, ¬(s))
└ ✔ false
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(q, ¬(r), t, q)
└ ✔ true
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(q, ¬(r), t, ¬(q))
└ ✔ false
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(q, ¬(r), ¬(t))
└ ✔ true
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(¬(q), r ∧ s ∧ t, ¬(r))
└ ✔ true
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

@test unroll_rules(r1_string) isa Vector{<:Rule}
print_model(io,unroll_rules(r1_string))
@test String(take!(io)) == """
1-element Vector{Rule{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}}
Rule{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐r ∧ s ∧ t
└ ✔ true
"""

@test unroll_rules(r2_string) isa Vector{<:Rule}
print_model(io,unroll_rules(r2_string))
@test String(take!(io)) == """
1-element Vector{Rule{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}}
Rule{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐¬(r)
└ ✔ true
"""

@test unroll_rules(d1_string) isa Vector{<:Rule}
print_model(io,unroll_rules(d1_string))
@test String(take!(io)) == """
3-element Vector{Rule{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}}
Rule{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐r ∧ s ∧ t
└ ✔ true
Rule{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐¬(r)
└ ✔ true
Rule{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⊤
└ ✔ true
"""

@test unroll_rules(rc1_string) isa Vector{<:Rule}
print_model(io,unroll_rules(rc1_string))
@test String(take!(io)) == """
1-element Vector{Rule{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}}
Rule{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐r ∧ s ∧ t
└ ✔ true
"""

@test unroll_rules(rcmodel) isa Vector{<:Rule}
print_model(io,unroll_rules(rcmodel))
@test String(take!(io)) == """
1-element Vector{Rule{Int64, LogicalTruthCondition{Formula}, ConstantModel{Int64}}}
Rule{Int64, LogicalTruthCondition{Formula}, ConstantModel{Int64}}
┐p ∧ q ∧ r ∧ p ∧ q ∧ r ∧ p ∧ q ∧ r
└ ✔ 1
"""

@test unroll_rules(b_nsx) isa Vector{<:Rule}
print_model(io,unroll_rules(b_nsx))
@test String(take!(io)) == """
2-element Vector{Rule{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}}
Rule{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐q
└ ✔ true
Rule{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐¬(q)
└ ✔ false
"""

@test unroll_rules(b_fsx) isa Vector{<:Rule}
print_model(io,unroll_rules(b_fsx))
@test String(take!(io)) == """
2-element Vector{Rule{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}}
Rule{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐s
└ ✔ true
Rule{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐¬(s)
└ ✔ false
"""

@test unroll_rules(b_fdx) isa Vector{<:Rule}
print_model(io,unroll_rules(b_fdx))
@test String(take!(io)) == """
3-element Vector{Rule{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}}
Rule{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐t ∧ q
└ ✔ true
Rule{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐t ∧ ¬(q)
└ ✔ false
Rule{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐¬(t)
└ ✔ true
"""

@test unroll_rules(b_p) isa Vector{<:Rule}
print_model(io,unroll_rules(b_p))
@test String(take!(io)) == """
5-element Vector{Rule{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}}
Rule{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐r ∧ s
└ ✔ true
Rule{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐r ∧ ¬(s)
└ ✔ false
Rule{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐¬(r) ∧ t ∧ q
└ ✔ true
Rule{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐¬(r) ∧ t ∧ ¬(q)
└ ✔ false
Rule{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐¬(r) ∧ ¬(t)
└ ✔ true
"""

@test unroll_rules(dt1) isa Vector{<:Rule}
print_model(io,unroll_rules(dt1))
@test String(take!(io)) == """
5-element Vector{Rule{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}}
Rule{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐r ∧ s
└ ✔ true
Rule{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐r ∧ ¬(s)
└ ✔ false
Rule{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐¬(r) ∧ t ∧ q
└ ✔ true
Rule{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐¬(r) ∧ t ∧ ¬(q)
└ ✔ false
Rule{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐¬(r) ∧ ¬(t)
└ ✔ true
"""

@test unroll_rules(dt2) isa Vector{<:Rule}
print_model(io,unroll_rules(dt2))
@test String(take!(io)) == """
3-element Vector{Rule{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}}
Rule{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐t ∧ q
└ ✔ true
Rule{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐t ∧ ¬(q)
└ ✔ false
Rule{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐¬(t)
└ ✔ true
"""

@test unroll_rules(msm) isa Vector{<:Rule}
print_model(io,unroll_rules(msm))
@test String(take!(io)) == """
6-element Vector{Rule{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}}
Rule{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐q ∧ r ∧ s
└ ✔ true
Rule{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐q ∧ r ∧ ¬(s)
└ ✔ false
Rule{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐q ∧ ¬(r) ∧ t ∧ q
└ ✔ true
Rule{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐q ∧ ¬(r) ∧ t ∧ ¬(q)
└ ✔ false
Rule{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐q ∧ ¬(r) ∧ ¬(t)
└ ✔ true
Rule{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐¬(q) ∧ r ∧ s ∧ t ∧ ¬(r)
└ ✔ true
"""

#=
unroll_rules(rule_r)
unroll_rules(branch_r)
unroll_rules.([rfloat_number, dlmodel, dlmodel_integer, bmodel_integer, bmodel, bmodel_mixed, bmodel_mixed_number, dtmodel0, dtmodel, ms_model])
=#

############################################################################################
############################### Testing convert ############################################
############################################################################################

@test convert(Rule,rc1_string) isa Rule
@test convert(Rule,rc2_string) isa Rule

@test convert(Rule, rcmodel) isa Rule

#=
@test convert(RuleCascade,r1_string) isa RuleCascade
print_model(io,convert(RuleCascade,r1_string))
@test String(take!(io)) == """
RuleCascade{String, LogicalTruthCondition{SyntaxTree{Union{NamedOperator{:∧}, Proposition{String}}, NamedOperator{:∧}}}, ConstantModel{String}}
┐⩚(r ∧ s ∧ t)
└ ✔ true
"""
@test_nowarn convert(RuleCascade,r2_string)
print_model(io,convert(RuleCascade,r2_string))
@test String(take!(io)) == """
RuleCascade{String, LogicalTruthCondition{SyntaxTree{Union{NamedOperator{:¬}, Proposition{String}}, NamedOperator{:¬}}}, ConstantModel{String}}
┐⩚(¬(r))
└ ✔ true
"""
=#
