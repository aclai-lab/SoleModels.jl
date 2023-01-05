using Reexport
using FunctionWrappers
using FunctionWrappers: FunctionWrapper
using Base
using Test
using SoleLogics: Proposition, AbstractFormula, SyntaxTree, ¬, ∧, ⊤
using SoleModels: ConstantModel, FinalModel, LogicalTruthCondition, DecisionForest, DecisionList, DecisionTree, Branch, Rule, RuleCascade, AbstractBooleanCondition
using SoleModels: unroll_rules, unroll_rules_cascade, formula, root

#Riga 14-15 di base.jl
#abstract type AbstractInstance end
#struct AbstractDataset end

#Sostituto di SoleLogics.TOP
#const TOP = SoleLogics.parseformula("⊤")

# Three possible outcome - FinalModel
outcome_int =  @test_nowarn ConstantModel(2)
outcome_float = @test_nowarn ConstantModel(1.5)
outcome_string = @test_nowarn ConstantModel("true")
outcome_string2 = @test_nowarn ConstantModel("false")

# String Propositions and SyntaxTree consequent
prop_r = @test_nowarn Proposition("r")
prop_s = @test_nowarn Proposition("s")
prop_t = @test_nowarn Proposition("t")
prop_q = @test_nowarn Proposition("q")

st_r = @test_nowarn SyntaxTree(prop_r)
st_s = @test_nowarn SyntaxTree(prop_s)
st_t = @test_nowarn SyntaxTree(prop_t)
st_q = @test_nowarn SyntaxTree(prop_q)

# Integer Propositions and SyntaxTree consequent
prop_1 = @test_nowarn Proposition(1)
prop_100 = @test_nowarn Proposition(100)

st_1 = @test_nowarn SyntaxTree(prop_1)
st_100 = @test_nowarn SyntaxTree(prop_100)

# LogicalTruthCondition
cond_r = @test_nowarn LogicalTruthCondition{SyntaxTree}(st_r)
cond_s = @test_nowarn LogicalTruthCondition{SyntaxTree}(st_s)
cond_t = @test_nowarn LogicalTruthCondition{SyntaxTree}(st_t)
cond_q = @test_nowarn LogicalTruthCondition{SyntaxTree}(st_q)

cond_not_r = @test_nowarn LogicalTruthCondition{SyntaxTree}(¬(formula(cond_r)))
cond_not_s = @test_nowarn LogicalTruthCondition{SyntaxTree}(¬(formula(cond_s)))

cond_1 = @test_nowarn LogicalTruthCondition{SyntaxTree}(st_1)
cond_100 = @test_nowarn LogicalTruthCondition{SyntaxTree}(st_100)

# Rule
r1_string = @test_nowarn Rule(LogicalTruthCondition(∧(∧(prop_r,prop_s),prop_t)),outcome_string)
r2_string = @test_nowarn Rule(LogicalTruthCondition(¬(prop_r)),outcome_string)

# DecisionList
d1_string = @test_nowarn DecisionList([r1_string,r2_string],outcome_string)

# RuleCascade
rc1_string = @test_nowarn RuleCascade([cond_r,cond_s,cond_t],outcome_string)
rc2_string = @test_nowarn RuleCascade([cond_r],outcome_string)

# Branch
b_nsx = @test_nowarn Branch(cond_q,outcome_string,outcome_string2)
b_fsx = @test_nowarn Branch(cond_s,outcome_string,outcome_string2)
b_fdx = @test_nowarn Branch(cond_t,b_nsx,outcome_string)
b_p = @test_nowarn Branch(cond_r,b_fsx,b_fdx)

# DecisionTree
dt1 = @test_nowarn DecisionTree(b_p)
dt2 = @test_nowarn DecisionTree(b_fdx)

# DecisionForest
df = @test_nowarn DecisionForest([dt1,dt2])


############################################################################################
###################### Testing unroll_rules_cascade ########################################
############################################################################################

@test_nowarn unroll_rules_cascade(outcome_int)
@test_nowarn unroll_rules_cascade(outcome_float)
@test_nowarn unroll_rules_cascade(outcome_string)
@test_nowarn unroll_rules_cascade(outcome_string2)

@test_nowarn unroll_rules_cascade(r1_string)
@test_nowarn unroll_rules_cascade(r2_string)

@test_nowarn unroll_rules_cascade(d1_string)

@test_nowarn unroll_rules_cascade(rc1_string)

@test_nowarn unroll_rules_cascade(b_nsx)
@test_nowarn unroll_rules_cascade(b_fsx)
@test_nowarn unroll_rules_cascade(b_fdx)
@test_nowarn unroll_rules_cascade(b_p)

@test_nowarn unroll_rules_cascade(dt1)
@test_nowarn unroll_rules_cascade(dt2)

@test_nowarn unroll_rules_cascade(df)

############################################################################################
############################ Testing unroll_rules ##########################################
############################################################################################


@test_nowarn unroll_rules(outcome_int)
@test_nowarn unroll_rules(outcome_float)
@test_nowarn unroll_rules(outcome_string)
@test_nowarn unroll_rules(outcome_string2)

@test_nowarn unroll_rules(r1_string)
@test_nowarn unroll_rules(r2_string)

@test_nowarn unroll_rules(d1_string)

# TODO: to fix
#@test_nowarn unroll_rules(rc1_string)

@test_nowarn unroll_rules(b_nsx)
@test_nowarn unroll_rules(b_fsx)
@test_nowarn unroll_rules(b_fdx)
@test_nowarn unroll_rules(b_p)

@test_nowarn unroll_rules(dt1)
@test_nowarn unroll_rules(dt2)

@test_nowarn unroll_rules(df)

############################################################################################
############################ Testing unroll_rules ##########################################
############################################################################################

@test_nowarn convert(Rule,[cond_r],outcome_string)

@test_nowarn convert(Rule,rc1_string)
@test_nowarn convert(Rule,rc2_string)

@test_nowarn convert(RuleCascade,r1_string)
@test_nowarn convert(RuleCascade,r2_string)

#=

#Testing list_paths
list_paths(branch_r)

#Testing convert function --- COMPLETED
convert(Rule,rule_cascade_rs)
convert(RuleCascade,ruleset[1])

#Testing rule_length ---- COMPLETED
rule_length(rule_r)
rule_length(ruleset[1])
=#
