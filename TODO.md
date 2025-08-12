# Sparse notes

- Rename: listrules -> ruleset
☐ Optimize Sole apply/predict di LeftMostLinearFormulas e su dataset


☐ AbstractTrees interface for SoleModels
☐ AbstractInterpretationSet/AbstractLogiset are probably the same thing!!

☐ There is an interesting new pattern between DecisionTree and Branch!!! DecisionTree acts as a guard! Maybe it's better if it's not a type, but just a function that builds Branch's or Finals!
☐ The same goes for DecisionForests, which should be a sort of alias for `Ensemble{DecisionTree}`. Type to create: `Ensemble`, type to remove: `DecisionForest`.
☐ Conversion functions between models, for example: `convert(::Type{DecisionList}, tree::DecisionList)`
☐ Check `formula2natlang` and here, Exercise 2: https://github.com/aclai-lab/modal-symbolic-learning-course/blob/main/Day3-gesture-recognition.ipynb. It’s a (limited, experimental) function that translates formulas into English. We should add some further simplification for cases like "(∃ interval where (min[V5] ≥ 0.85)) and (∀ intervals (min[V1] < 0.43))"! When the formula is (∃ interval where (min[V5] ≥ X)), it means that, over the entire series (i.e., over the largest interval, min[V5] ≥ X).
☐ TODO translate MDT in the propositional case must remove the existential and global quantifiers. Maybe it already does…?
☐ remove nvariables logiset is wrong and dangerous
☐ remove nvariables for MultiLogiset: dangerous.
☐ Learn from FeaturedGraph's: https://yuehhua.github.io/GraphSignals.jl/stable/manual/featuredgraph/#Pass-FeaturedGraph-to-CUDA

☐ Switch the types in ScalarCondition, and require the parser to specify like ScalarCondition{FT}, or ScalarCondition, featvaltype = FT. One should be able to parse IA formulas from a string like this:
    `φ = parseformula("[L] ( min[V1] > 0.5 ∨ min[V2] ≤ 10 )", [box(IA_L)]; atom_parser = str->parsecondition(ScalarCondition, str))`
    `φ = parseformula("[L] ( min[V1] > 0.5 ∨ min[V2] ≤ 10 )", SoleLogics.diamondsandboxes(IARelations); atom_parser = str->parsecondition(ScalarCondition, str))`
☐ TODO or of multiformulas…?? Free SyntaxBranch…?
☐ datasets:
☐ TODO: note that when checking a formula like f1 > 3, everything gets memoized in the large table!!
    add a parameter so that formulas meeting certain parameters are not cached normally in the large table, but instead, you just do a lookup for them.
    ☐ chained checking
    TODO: apply_test_operator(test_operator, gamma, threshold(featcond)) with the result of compute_chained_threshold
    optimize collateworlds with representatives aggr etc.
☐ non-uniform generalization
☐ AlphabetOfAny{C where C<:Condition{F where F<:Feature{P where P<:Atom}}}
☐ TODO generic relational/global structure that holds an indefinite number of relations/metaconditions
  ☐ scitype = Image/TimeSeries?
☐ Translate symbolic models into logical formulas. (ConstantModel("C_1") -> Atom(ConstantModel("C_1")))


Features:
    ☐ struct EnsembleModel (with parametrized aggregation) and DecisionForest
    ☐ PatchModel, a closed model providing a default consequent to an open model
    ✔ Add supporting_labels field (vector) @done(24-05-31 11:12)
    # Vector of labels of instances on which the rule is built (i.e., those not covered by previous rules), and in
    # the constant model info, include a supp_labels field with the labels of the instances that, among these, are covered by the rule.
    ☐ Add predicted_labels field (perhaps)
    # Labels predicted by the model, but initially the supporting_labels are sufficient
    # to calculate various metrics

Test:
    ✔ Testing parser outcome @done(24-05-31 11:12)
    ✔ Correct supporting_labels @done(24-05-31 11:12)
    ✔ Correct info (consequent/rule) @done(24-05-31 11:12)
    # Distribution of covered examples for consequent
    # Distribution of examples on which the rule was built
    ✔ Testing parser error @done(24-05-31 11:12)
    ☐ Add test for rule-extraction.jl 
Questions:
    ✔ Readmetrics for CN2 statistics @done(24-05-31 11:12)
