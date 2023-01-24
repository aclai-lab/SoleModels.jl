using Reexport
using FunctionWrappers
using FunctionWrappers: FunctionWrapper
using Base
using Test
using SoleLogics
using SoleLogics: Proposition, SyntaxTree, ¬, ∧, ⊤
using SoleModels
using SoleModels: FormulaOrTree, ConstantModel, FinalModel, LogicalTruthCondition, DecisionForest, DecisionList, DecisionTree, Branch, Rule, RuleCascade, AbstractBooleanCondition
using SoleModels: unroll_rules, unroll_rules_cascade, formula, root

#Sostituto di SoleLogics.TOP
# const TOP = SoleLogics.parseformula("⊤")

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

# IOBuffer
io = @test_nowarn IOBuffer()

############################################################################################
###################### Testing unroll_rules_cascade ########################################
############################################################################################

# TODO: test output
@test unroll_rules_cascade(outcome_int) isa Vector{<:ConstantModel}
@test unroll_rules_cascade(outcome_float) isa Vector{<:ConstantModel}
@test unroll_rules_cascade(outcome_string) isa Vector{<:ConstantModel}
@test unroll_rules_cascade(outcome_string2) isa Vector{<:ConstantModel}

@test unroll_rules_cascade(r1_string) isa Vector{<:RuleCascade}
print_model(io,unroll_rules_cascade(r1_string))
@test String(take!(io)) == """
1-element Vector{RuleCascade{String, LogicalTruthCondition{SyntaxTree{Union{NamedOperator{:∧}, Proposition{String}}, NamedOperator{:∧}}}, ConstantModel{String}}}
RuleCascade{String, LogicalTruthCondition{SyntaxTree{Union{NamedOperator{:∧}, Proposition{String}}, NamedOperator{:∧}}}, ConstantModel{String}}
┐⩚(r ∧ s ∧ t)
└ ✔ true
"""

@test unroll_rules_cascade(r2_string) isa Vector{<:RuleCascade}
print_model(io,unroll_rules_cascade(r2_string))
@test String(take!(io)) == """
1-element Vector{RuleCascade{String, LogicalTruthCondition{SyntaxTree{Union{NamedOperator{:¬}, Proposition{String}}, NamedOperator{:¬}}}, ConstantModel{String}}}
RuleCascade{String, LogicalTruthCondition{SyntaxTree{Union{NamedOperator{:¬}, Proposition{String}}, NamedOperator{:¬}}}, ConstantModel{String}}
┐⩚(¬(r))
└ ✔ true
"""

@test unroll_rules_cascade(rc1_string) isa Vector{<:RuleCascade}
print_model(io,unroll_rules_cascade(rc1_string))
@test String(take!(io)) == """
1-element Vector{RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}}
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(r AND s AND t)
└ ✔ true
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
┐⩚(t AND q)
└ ✔ true
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(t AND ¬(q))
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
┐⩚(r AND s)
└ ✔ true
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(r AND ¬(s))
└ ✔ false
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(¬(r) AND t AND q)
└ ✔ true
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(¬(r) AND t AND ¬(q))
└ ✔ false
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(¬(r) AND ¬(t))
└ ✔ true
"""

#@test unroll_rules_cascade(d1_string) isa Vector{<:RuleCascade}

@test unroll_rules_cascade(dt1) isa Vector{<:RuleCascade}
print_model(io,unroll_rules_cascade(dt1))
@test String(take!(io)) == """
5-element Vector{RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}}
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(r AND s)
└ ✔ true
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(r AND ¬(s))
└ ✔ false
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(¬(r) AND t AND q)
└ ✔ true
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(¬(r) AND t AND ¬(q))
└ ✔ false
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(¬(r) AND ¬(t))
└ ✔ true
"""

@test unroll_rules_cascade(dt2) isa Vector{<:RuleCascade}
print_model(io,unroll_rules_cascade(dt2))
@test String(take!(io)) == """
3-element Vector{RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}}
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(t AND q)
└ ✔ true
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(t AND ¬(q))
└ ✔ false
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(¬(t))
└ ✔ true
"""
#=
@test unroll_rules_cascade(df) isa Vector{<:RuleCascade}
print_model(io,unroll_rules_cascade(df))
@test String(take!(io)) == """
8-element Vector{RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}}
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(r AND s)
└ ✔ true
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(r AND ¬(s))
└ ✔ false
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(¬(r) AND t AND q)
└ ✔ true
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(¬(r) AND t AND ¬(q))
└ ✔ false
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(¬(r) AND ¬(t))
└ ✔ true
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(t AND q)
└ ✔ true
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(t AND ¬(q))
└ ✔ false
RuleCascade{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}
┐⩚(¬(t))
└ ✔ true
"""
=#

############################################################################################
############################ Testing unroll_rules ##########################################
############################################################################################


@test unroll_rules(outcome_int) isa Vector{<:ConstantModel}
@test unroll_rules(outcome_float) isa Vector{<:ConstantModel}
@test unroll_rules(outcome_string) isa Vector{<:ConstantModel}
@test unroll_rules(outcome_string2) isa Vector{<:ConstantModel}

@test unroll_rules(r1_string) isa Vector{<:Rule}
print_model(io,unroll_rules(r1_string))
@test String(take!(io)) == """
1-element Vector{Rule{String, LogicalTruthCondition{SyntaxTree{Union{NamedOperator{:∧}, Proposition{String}}, NamedOperator{:∧}}}, ConstantModel{String}}}
Rule{String, LogicalTruthCondition{SyntaxTree{Union{NamedOperator{:∧}, Proposition{String}}, NamedOperator{:∧}}}, ConstantModel{String}}
┐r ∧ s ∧ t
└ ✔ true
"""

@test unroll_rules(r2_string) isa Vector{<:Rule}
print_model(io,unroll_rules(r2_string))
@test String(take!(io)) == """
1-element Vector{Rule{String, LogicalTruthCondition{SyntaxTree{Union{NamedOperator{:¬}, Proposition{String}}, NamedOperator{:¬}}}, ConstantModel{String}}}
Rule{String, LogicalTruthCondition{SyntaxTree{Union{NamedOperator{:¬}, Proposition{String}}, NamedOperator{:¬}}}, ConstantModel{String}}
┐¬(r)
└ ✔ true
"""

@test unroll_rules(d1_string) isa Vector{<:Rule}
print_model(io,unroll_rules(d1_string))
@test String(take!(io)) == """
3-element Vector{Rule{String, C, ConstantModel{String}} where C<:AbstractBooleanCondition}
Rule{String, LogicalTruthCondition{SyntaxTree{Union{NamedOperator{:∧}, Proposition{String}}, NamedOperator{:∧}}}, ConstantModel{String}}
┐r ∧ s ∧ t
└ ✔ true
Rule{String, LogicalTruthCondition{SyntaxTree{Union{NamedOperator{:¬}, Proposition{String}}, NamedOperator{:¬}}}, ConstantModel{String}}
┐¬(r)
└ ✔ true
Rule{String, LogicalTruthCondition{SyntaxTree{SoleLogics.TopOperator, SoleLogics.TopOperator}}, ConstantModel{String}}
┐SoleLogics.TopOperator()
└ ✔ true
"""

# TODO: to fix
#@test_nowarn unroll_rules(rc1_string)

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

#=
@test unroll_rules(df) isa Vector{<:Rule}
print_model(io,unroll_rules(df))
@test String(take!(io)) == """
8-element Vector{Rule{String, LogicalTruthCondition{SyntaxTree}, ConstantModel{String}}}
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
=#

############################################################################################
############################ Testing unroll_rules ##########################################
############################################################################################

#@test_nowarn convert(Rule,[cond_r],outcome_string)

#@test_nowarn convert(Rule,rc1_string)
#@test_nowarn convert(Rule,rc2_string)

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
