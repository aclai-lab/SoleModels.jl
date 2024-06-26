using SoleModels
using SoleLogics
using FunctionWrappers: FunctionWrapper
using SoleModels: AbstractModel
using SoleModels: ConstantModel, LeafModel
using Test

phi = SoleLogics.parseformula("p")
phi2 = SoleLogics.parseformula("q∨r")

cmodel_supporting_labels = ["0","0","0","0","0","1","1"]
rmodel_supporting_labels = ["1", "1", cmodel_supporting_labels...]
all_supporting_labels = ["0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", rmodel_supporting_labels...]

cmodel = ConstantModel("0", (; supporting_labels = cmodel_supporting_labels))
rule1 = Rule(phi, cmodel, (; supporting_labels = rmodel_supporting_labels))
rule2 = Rule(phi2, rule1, (; supporting_labels = all_supporting_labels))

real_conf = SoleModels.accuracy(fill(SoleModels.outcome(cmodel), length(cmodel_supporting_labels)), cmodel_supporting_labels)
baseline_r1_conf = SoleModels.accuracy(fill(SoleModels.outcome(cmodel), length(rmodel_supporting_labels)), rmodel_supporting_labels)
baseline_r2_conf = SoleModels.accuracy(fill(SoleModels.outcome(cmodel), length(all_supporting_labels)), all_supporting_labels)

cmet = readmetrics(cmodel)
@test isapprox(cmet.coverage, 1.0)
@test isapprox(cmet.confidence, real_conf)
@test isapprox(cmet.lift, 1.0)

r1met = readmetrics(rule1)
@test isapprox(r1met.coverage, length(cmodel_supporting_labels)/length(rmodel_supporting_labels))
@test isapprox(r1met.confidence, real_conf)
@test isapprox(r1met.lift, real_conf/baseline_r1_conf)

r2met = readmetrics(rule2)
@test isapprox(r2met.coverage, length(cmodel_supporting_labels)/length(all_supporting_labels))
@test isapprox(r2met.confidence, real_conf)
@test isapprox(r2met.lift, real_conf/baseline_r2_conf)
