using Revise

using Reexport
using FunctionWrappers: FunctionWrapper
using Test
using SoleLogics
using SoleModels
using SoleModels: AbstractModel
using SoleModels: ConstantModel, LeafModel
using SoleModels: listrules, displaymodel, submodels

io = IOBuffer()

# parse_other_kind_of_formula = SoleLogics.parsebaseformula
parse_other_kind_of_formula = SoleLogics.parseformula

################################### LeafModel #############################################
outcome_int =  @test_nowarn ConstantModel(2)
outcome_float = @test_nowarn ConstantModel(1.5)
outcome_string = @test_nowarn ConstantModel("YES")
outcome_string2 = @test_nowarn ConstantModel("NO")


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
@test_nowarn ConstantModel{AbstractFloat}(const_float)
cmodel_number = @test_nowarn ConstantModel{Number}(const_float)
cmodel_integer = @test_nowarn ConstantModel{Int}(const_integer)

cmodels = @test_nowarn [cmodel_string, cmodel_float, cmodel_number, cmodel_integer]
cmodels_num = @test_nowarn [cmodel_float, cmodel_number, cmodel_integer]

@test [cmodel_string, cmodel_float, cmodel_number, cmodel_integer] isa Vector{ConstantModel}
@test_nowarn ConstantModel[cmodel_string, cmodel_float]
@test_throws MethodError ConstantModel{String}[cmodel_string, cmodel_float]
# @test_broken ConstantModel{Int}[cmodel_number, cmodel_integer]
# @test_broken ConstantModel{Number}[cmodel_number, cmodel_integer]

##################### String Atoms and SyntaxTree consequent ########################
prop_r = @test_nowarn Atom("r")
prop_s = @test_nowarn Atom("s")
prop_t = @test_nowarn Atom("t")
prop_q = @test_nowarn Atom("q")

st_r = @test_nowarn SyntaxTree(prop_r)
st_s = @test_nowarn SyntaxTree(prop_s)
st_t = @test_nowarn SyntaxTree(prop_t)
st_q = @test_nowarn SyntaxTree(prop_q)

#################### Integer Atoms and SyntaxTree consequent ########################
prop_1 = @test_nowarn Atom(1)
prop_100 = @test_nowarn Atom(100)

##################################### SyntaxTree ###########################################
st_1 = @test_nowarn SyntaxTree(prop_1)
st_100 = @test_nowarn SyntaxTree(prop_100)

################################### Formulas ###############################################
p = @test_nowarn parse_other_kind_of_formula("p")
p_tree = @test_nowarn SoleLogics.parseformula("p")

# phi = @test_nowarn parse_other_kind_of_formula("p∧q∨r")
# phi_tree = @test_nowarn SoleLogics.parseformula("p∧q∨r")

# phi2 = @test_nowarn parse_other_kind_of_formula("q∧s→r")
# phi2_tree = @test_nowarn SoleLogics.parseformula("q∧s→r")


phi = @test_nowarn parse_other_kind_of_formula("p∧q∨r")
phi_tree = @test_nowarn SoleLogics.parseformula("p∧q∨r")

phi2 = @test_nowarn parse_other_kind_of_formula("q∧s→r")
phi2_tree = @test_nowarn SoleLogics.parseformula("q∧s→r")

formula_p = @test_nowarn parse_other_kind_of_formula("p")
formula_q = @test_nowarn parse_other_kind_of_formula("q")
formula_r = @test_nowarn parse_other_kind_of_formula("r")
formula_s = @test_nowarn parse_other_kind_of_formula("s")

############################### SyntaxTree ######################################
st_not_r = @test_nowarn ¬st_r
st_not_s = @test_nowarn ¬st_s

##################################### Rule #################################################
r1_string = @test_nowarn Rule((∧(∧(prop_r,prop_s),prop_t)),outcome_string)
r2_string = @test_nowarn Rule((¬(prop_r)),outcome_string)

r_true_string = @test_nowarn Rule(outcome_string)
r_true_number = @test_nowarn Rule(cmodel_number)

r_true_string = @test_nowarn Rule(formula_p, outcome_string)

r1_r2_string = @test_nowarn Rule((∧(∧(prop_r,prop_s),prop_t)), r2_string)

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
# @test typeof(rmodel_float) != typeof(Rule{Float64,Union{Rule{Float64},LeafModel{Float64}}}(phi,rmodel_float0))
# @test typeof(rmodel_float) == typeof(Rule{Float64,Union{Rule,ConstantModel}}(phi,rmodel_float0))

rmodel2_float = @test_nowarn Rule(phi2, rmodel_float)

@test_nowarn [Rule{<:Any}(phi, c) for c in cmodels]
@test_nowarn [Rule{Number}(phi, c) for c in cmodels_num]
@test_nowarn [Rule{Number}(phi, c) for c in cmodels_num]

rmodel3 = @test_nowarn Rule{Number}(phi,1)
# rmodel4 = @test_nowarn Rule{Number,ConstantModel{Number}}(phi, 1)
# @test_nowarn [rmodel3, rmodel4]

# rmodel3 = @test_nowarn Rule{Number,ConstantModel{Number}}(phi,1)
@test rmodel3 isa Rule{Number}
# @test Rule{Number,ConstantModel{Int}}(phi, 1) isa Rule{Number, Union{ConstantModel{Number}}}
# @test Rule{Int,ConstantModel{Number}}(phi, 1) isa Rule{Int, Union{ConstantModel{Int}}}
# @test_throws MethodError Rule{Int,ConstantModel{Number}}(phi, 1.0)

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

rules = @test_nowarn [rmodel_number, rmodel_integer, Rule(phi, cmodel_float)] # , rmodel_bounded_float]
dlmodel = @test_nowarn DecisionList(rules, defaultconsequent)
@test outputtype(dlmodel) == Union{outcometype(defaultconsequent),outcometype.(rules)...}

rules_integer = @test_nowarn [Rule(phi, cmodel_integer), Rule(phi, cmodel_integer)]
dlmodel_integer = @test_nowarn DecisionList(rules_integer, defaultconsequent)
@test outputtype(dlmodel_integer) == Union{outcometype(defaultconsequent),outcometype.(rules_integer)...}

################################### Branch #################################################
b_nsx = @test_nowarn Branch(st_q,outcome_string,outcome_string2)
b_fsx = @test_nowarn Branch(st_s,outcome_string,outcome_string2)
b_fdx = @test_nowarn Branch(st_t,b_nsx,outcome_string)
b_p = @test_nowarn Branch(st_r,b_fsx,b_fdx)

bmodel_integer = @test_nowarn Branch(phi, dlmodel_integer, dlmodel_integer)
@test outputtype(bmodel_integer) == Int
bmodel = @test_nowarn Branch(phi, dlmodel_integer, dlmodel)
@test outputtype(bmodel) == Union{outcometype.([dlmodel_integer,dlmodel])...}
@test iscomplete(bmodel)

bmodel_mixed = @test_nowarn Branch(phi, rmodel_float, dlmodel_integer)
@test Branch(phi, rmodel_float, dlmodel_integer) isa Branch{Union{Float64,Int}}
bmodel_mixed_number = @test_nowarn Branch(phi, rmodel_number, dlmodel)
@test Branch(phi, rmodel_number, dlmodel) isa Branch{Number}
@test !iscomplete(bmodel_mixed)
@test outputtype(bmodel_mixed) == Union{Nothing,Float64,Int}

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

branch_true = @test_nowarn Branch(TOP, (branch_r, "yes"))

@test typeof(branch_r0) == typeof(branch_r)

rule_r = @test_nowarn Rule(formula_r, branch_r)

branch_r_mixed = @test_nowarn Branch(formula_r, (rule_r, "no"))

############################### DecisionTree ###############################################
dt1 = @test_nowarn DecisionTree(b_p)
dt2 = @test_nowarn DecisionTree(b_fdx)

dtmodel0 = @test_nowarn DecisionTree("1")
dtmodel = @test_nowarn DecisionTree(branch_r)

############################## DecisionForest ##############################################
df = @test_nowarn DecisionForest([dt1,dt2])

############################### MixedModel #########################################
b_msm = @test_nowarn Branch(st_q,outcome_int,outcome_float)
dt_msm = @test_nowarn DecisionTree(b_msm)
msm = @test_nowarn MixedModel(dt_msm)

msmodel = @test_nowarn MixedModel(dtmodel)

complex_mixed_model = @test_nowarn Branch(formula_r, (dtmodel, dlmodel))

@test_nowarn MixedModel("1")
@test_nowarn MixedModel(const_funwrap)
@test_nowarn MixedModel(dtmodel)
@test_nowarn MixedModel(dlmodel)
ms_model0 = MixedModel(complex_mixed_model)

MixedModel(MixedModel("1"))
MixedModel(MixedModel(complex_mixed_model))
MixedModel(MixedModel(MixedModel(complex_mixed_model)))
ms_model1 = MixedModel(ms_model0)
ms_model = MixedModel(ms_model1)
ms_model = MixedModel(ms_model)
ms_model = MixedModel(ms_model)

@test typeof(ms_model1) == typeof(ms_model)

############################################################################################
#################################### Convert models ########################################
############################################################################################

@test convert(AbstractModel{Int}, cmodel_number) isa AbstractModel{Int}
@test_throws MethodError convert(AbstractModel{<:Int}, cmodel_number)

############################################################################################
############################ Testing immediatesubmodels ####################################
############################################################################################

@test_nowarn immediatesubmodels(outcome_int)
@test_nowarn immediatesubmodels(outcome_float)
@test_nowarn immediatesubmodels(outcome_string)
@test_nowarn immediatesubmodels(outcome_string2)
@test_nowarn immediatesubmodels(cmodel_string)

@test immediatesubmodels(outcome_int) isa Vector{Vector{<:AbstractModel{<:Int64}}}
@test immediatesubmodels(outcome_float) isa Vector{Vector{<:AbstractModel{<:Float64}}}
@test immediatesubmodels(outcome_string) isa Vector{Vector{<:AbstractModel{<:String}}}
@test immediatesubmodels(outcome_string2) isa Vector{Vector{<:AbstractModel{<:String}}}
@test immediatesubmodels(cmodel_string) isa Vector{Vector{<:AbstractModel{<:String}}}

@test immediatesubmodels(r1_string) isa Vector{<:AbstractModel}
@test_broken join(displaymodel.(immediatesubmodels(r1_string); header = false)) == """
YES
"""

@test immediatesubmodels(r2_string) isa Vector{<:AbstractModel}
@test_broken join(displaymodel.(immediatesubmodels(r2_string); header = false)) == """
YES
"""

@test immediatesubmodels(b_nsx) isa Vector{<:AbstractModel}
@test immediatesubmodels(b_fsx) isa Vector{<:AbstractModel}
@test immediatesubmodels(b_fdx) isa Vector{<:AbstractModel}
@test immediatesubmodels(b_p) isa Vector{<:AbstractModel}

@test_broken join(displaymodel.(immediatesubmodels(b_nsx); header = false)) == """
YES
NO
"""

@test_broken join(displaymodel.(immediatesubmodels(b_fsx); header = false)) == """
YES
NO
"""

@test_broken join(displaymodel.(immediatesubmodels(b_fdx); header = false)) == """
┐ q
├ ✔ YES
└ ✘ NO
YES
"""

@test_broken join(displaymodel.(immediatesubmodels(b_p); header = false)) == """
┐ s
├ ✔ YES
└ ✘ NO
┐ t
├ ✔ ┐ q
│   ├ ✔ YES
│   └ ✘ NO
└ ✘ YES
"""

@test immediatesubmodels(d1_string) isa Vector{<:AbstractModel}
@test_broken join(displaymodel.(immediatesubmodels(d1_string); header = false)) == """
┐(r ∧ s) ∧ t
└ ✔ YES
┐¬(r)
└ ✔ YES
YES
"""

@test immediatesubmodels(dt1) isa Vector{<:AbstractModel}
@test_broken join(displaymodel.(immediatesubmodels(dt1); header = false)) == """
┐ s
├ ✔ YES
└ ✘ NO
┐ t
├ ✔ ┐ q
│   ├ ✔ YES
│   └ ✘ NO
└ ✘ YES
"""

@test immediatesubmodels(dt2) isa Vector{<:AbstractModel}
@test_broken join(displaymodel.(immediatesubmodels(dt2); header = false)) == """
┐ q
├ ✔ YES
└ ✘ NO
YES
"""

@test immediatesubmodels(msm) isa Vector{<:AbstractModel}
@test_broken join(displaymodel.(immediatesubmodels(msm); header = false)) == """
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
@test_broken join(displaymodel.(submodels(r1_string); header = false)) == """
YES
"""

@test submodels(r2_string) isa Vector{<:AbstractModel}
@test_broken join(displaymodel.(submodels(r2_string); header = false)) == """
YES
"""

@test submodels(b_nsx) isa Vector{<:AbstractModel}
@test submodels(b_fsx) isa Vector{<:AbstractModel}
@test submodels(b_fdx) isa Vector{<:AbstractModel}
@test submodels(b_p) isa Vector{<:AbstractModel}

@test_broken join(displaymodel.(submodels(b_nsx); header = false)) == """
YES
NO
"""

@test_broken join(displaymodel.(submodels(b_fsx); header = false)) == """
YES
NO
"""

@test_broken join(displaymodel.(submodels(b_fdx); header = false)) == """
┐ q
├ ✔ YES
└ ✘ NO
YES
NO
YES
"""

@test_broken join(displaymodel.(submodels(b_p); header = false)) == """
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
@test_broken join(displaymodel.(submodels(d1_string); header = false)) == """
┐(r ∧ s) ∧ t
└ ✔ YES
YES
┐¬(r)
└ ✔ YES
YES
YES
"""

@test submodels(dt1) isa Vector{<:AbstractModel}
@test_broken join(displaymodel.(submodels(dt1); header = false)) == """
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
@test_broken join(displaymodel.(submodels(dt2); header = false)) == """
┐ q
├ ✔ YES
└ ✘ NO
YES
NO
YES
"""

@test submodels(msm) isa Vector{<:AbstractModel}
@test_broken join(displaymodel.(submodels(msm); header = false)) == """
2
1.5
"""

############################################################################################
############################ Testing listrules ##########################################
############################################################################################

@test_nowarn listrules(outcome_int)
@test_nowarn listrules(outcome_float)
@test_nowarn listrules(outcome_string)
@test_nowarn listrules(outcome_string2)
@test_nowarn listrules(cmodel_string)

@test !(listrules(outcome_int) isa Vector{<:ConstantModel})
@test !(listrules(outcome_float) isa Vector{<:ConstantModel})
@test !(listrules(outcome_string) isa Vector{<:ConstantModel})
@test !(listrules(outcome_string2) isa Vector{<:ConstantModel})
@test !(listrules(cmodel_string) isa Vector{<:ConstantModel})


@test_nowarn listrules(rule_r)
@test_nowarn ruleset = listrules(branch_r)
@test_nowarn listrules(dlmodel)

@test listrules(r1_string) isa Vector{<:Rule}
@test_broken join(displaymodel.(listrules(r1_string); header = false)) == """
┐(r ∧ s) ∧ t
└ ✔ YES
"""

@test listrules(r2_string) isa Vector{<:Rule}
@test_broken join(displaymodel.(listrules(r2_string); header = false)) == """
┐¬(r)
└ ✔ YES
"""

@test listrules(d1_string) isa Vector{<:Rule}
@test_broken join(displaymodel.(listrules(d1_string); header = false)) == """
┐(r ∧ s) ∧ t
└ ✔ YES
┐(¬((r ∧ s) ∧ t)) ∧ (¬(r))
└ ✔ YES
┐(¬((r ∧ s) ∧ t)) ∧ (¬((¬((r ∧ s) ∧ t)) ∧ (¬(r))))
└ ✔ YES
"""

@test listrules(b_nsx) isa Vector{<:Rule}
@test_broken join(displaymodel.(listrules(b_nsx); header = false)) == """
┐q
└ ✔ YES
┐¬(q)
└ ✔ NO
"""

@test listrules(b_fsx) isa Vector{<:Rule}
@test_broken join(displaymodel.(listrules(b_fsx); header = false)) == """
┐s
└ ✔ YES
┐¬(s)
└ ✔ NO
"""

@test listrules(b_fdx) isa Vector{<:Rule}
@test_broken join(displaymodel.(listrules(b_fdx); header = false)) == """
┐(t) ∧ (q)
└ ✔ YES
┐(t) ∧ (¬(q))
└ ✔ NO
┐¬(t)
└ ✔ YES
"""

@test listrules(b_p) isa Vector{<:Rule}
@test_broken join(displaymodel.(listrules(b_p); header = false)) == """
┐(r) ∧ (s)
└ ✔ YES
┐(r) ∧ (¬(s))
└ ✔ NO
┐(¬(r)) ∧ (t) ∧ (q)
└ ✔ YES
┐(¬(r)) ∧ (t) ∧ (¬(q))
└ ✔ NO
┐(¬(r)) ∧ (¬(t))
└ ✔ YES
"""

@test listrules(dt1) isa Vector{<:Rule}
@test_broken join(displaymodel.(listrules(dt1); header = false)) == """
┐(r) ∧ (s)
└ ✔ YES
┐(r) ∧ (¬(s))
└ ✔ NO
┐(¬(r)) ∧ (t) ∧ (q)
└ ✔ YES
┐(¬(r)) ∧ (t) ∧ (¬(q))
└ ✔ NO
┐(¬(r)) ∧ (¬(t))
└ ✔ YES
"""

@test listrules(dt2) isa Vector{<:Rule}
@test_broken join(displaymodel.(listrules(dt2); header = false)) == """
┐(t) ∧ (q)
└ ✔ YES
┐(t) ∧ (¬(q))
└ ✔ NO
┐¬(t)
└ ✔ YES
"""

@test listrules(msm) isa Vector{<:Rule}
@test_broken join(displaymodel.(listrules(msm); header = false)) == """
┐q
└ ✔ 2
┐¬(q)
└ ✔ 1.5
"""
