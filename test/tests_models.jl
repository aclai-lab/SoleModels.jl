using Reexport
using FunctionWrappers
using FunctionWrappers: FunctionWrapper
using Base
using SoleLogics
using SoleModels
using SoleModels: ConstantModel, FinalModel
using SoleModels: unroll_rules, unroll_rules_cascade

#Riga 14-15 di base.jl
#abstract type AbstractInstance end
#struct AbstractDataset end

#Sostituto di SoleLogics.TOP
const TOP = SoleLogics.build_tree("⊤")

formula_s = SoleLogics.build_tree("s")
formula_r = SoleLogics.build_tree("r")

branch_s = Branch(formula_s,("yes","no"))
branch_r = Branch(formula_r,(branch_s,"yes"))

outcomeString = ConstantModel("yes")

rule_r = Rule(formula_r,outcomeString)
rule_s = Rule(formula_s,outcomeString)

#decList = DecisionList([rule_r,rule_s],outcomeString)

rule_cascade_rs = RuleCascade([formula_r,formula_s],outcomeString)

# Testing unroll_rules ----- COMPLETED
unroll_rules(outcomeString)
unroll_rules(rule_r)
ruleset = unroll_rules(branch_r)
unroll_rules(decList)
unroll_rules(rule_cascade_rs)

# Testing unroll_rules_cascade ---- COMPLETED
unroll_rules_cascade(outcomeString)
unroll_rules_cascade(rule_r)
unroll_rules_cascade(branch_r)
unroll_rules_cascade(decList)
unroll_rules_cascade(rule_cascade_rs)

#Testing list_paths
list_paths(branch_r)

#Testing convert function --- COMPLETED
convert(Rule,rule_cascade_rs)
convert(RuleCascade,ruleset[1])

#Testing rule_length ---- COMPLETED
rule_length(rule_r)
rule_length(ruleset[1])
