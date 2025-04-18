################################################
        #              p
        #      ┌───────┴─────────────┐
        #      │                     r
        #      q                 ┌───┴───┐
        #      │                 s      "yes"
        #  ┌───┴───┐         ┌───┴───┐
        # "yes"   "no"      "yes"   "no"
##################################################

using SoleLogics
using SoleModels

formula_p = SoleLogics.parseformula("p")
formula_q = SoleLogics.parseformula("q")
formula_r = SoleLogics.parseformula("r")
formula_s = SoleLogics.parseformula("s")

branch_q = Branch(formula_q,("yes","no"),(;))
branch_s = Branch(formula_s,("yes","no"),(;))
branch_r = Branch(formula_r,(branch_s,"yes"),(;))

#dt_q = DecisionTree(branch_r,(;))


#Possibile path
path_all = [formula_p,formula_q,formula_s,formula_r,"yes"]
path_2 = [formula_p,formula_q,"yes"]
path_1 = [formula_p,"yes"]
path_0 = ["yes"]
