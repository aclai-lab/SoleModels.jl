using Revise

using SoleLogics
using SoleModels
using SoleModels: ConstantModel, FinalModel
using Test


buf = IOBuffer()

p = SoleLogics.build_tree("p")
phi = SoleLogics.build_tree("p∧q∨r")
phi2 = SoleLogics.build_tree("q∧s→r")

L = @test_nowarn Logic{:ModalLogic}

@test_nowarn ConstantModel(1,(;))
@test_nowarn ConstantModel(1)
@test_throws MethodError ConstantModel{Float64}(1,(;))

const_string = "Wow!"
const_float = 1.0
const_integer = 1

consts = @test_nowarn [const_string, const_float, const_integer]

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

@test convert(AbstractModel{Int}, cmodel_number) isa AbstractModel{Int}
@test_throws MethodError convert(AbstractModel{<:Int}, cmodel_number)

@test Rule(phi, cmodel_number) isa Rule{Number}
@test Rule(phi, cmodel_integer) isa Rule{Int}
@test Rule{Int}(phi, cmodel_number) isa Rule{Int}
@test Rule{Int}(phi, cmodel_integer) isa Rule{Int}
@test Rule{Number}(phi, cmodel_integer) isa Rule{Number}
@test Rule{Number}(phi, cmodel_number) isa Rule{Number}

@test_nowarn [Rule(phi, c) for c in consts]
@test_nowarn [Rule(phi, c) for c in cmodels]

@test_nowarn Rule{Float64}(phi,const_float)
rmodel_float = @test_nowarn Rule{Float64}(phi,const_float)
@test rmodel_float == Rule{Float64,Union{Rule{Float64},ConstantModel{Float64}}}(phi,const_float)
@test rmodel_float != Rule{Float64,Union{Rule{Float64},FinalModel{Float64}}}(phi,const_float)
@test rmodel_float == Rule{Float64,Union{Rule, ConstantModel}}(phi,const_float)

rmodel2_float = @test_nowarn Rule(phi2, rmodel_float)

@test_nowarn [Rule{<:Any}(phi, c) for c in cmodels]
@test_nowarn [Rule{Number}(phi, c) for c in cmodels_num]
@test_nowarn [Rule{Number}(phi, c) for c in cmodels_num]

rmodel3 = @test_nowarn Rule{Number}(phi,1)
rmodel4 = @test_nowarn Rule{Number,ConstantModel{Number}}(phi, 1)
@test_nowarn [rmodel3, rmodel4]

rmodel_number = @test_nowarn Rule{Number,ConstantModel{Number}}(phi,1)
@test rmodel_number == Rule{Number,Union{Rule{Number},ConstantModel{Number}}}(phi,1)
@test Rule{Number,ConstantModel{Int}}(phi, 1) isa Rule{Number, Union{ConstantModel{Number}, Rule{Number}}}
@test Rule{Int,ConstantModel{Number}}(phi, 1) isa Rule{Int, Union{ConstantModel{Int}, Rule{Int}}}
@test_throws MethodError Rule{Int,ConstantModel{Number}}(phi, 1.0)

@test rmodel_number == Rule{Number,Union{Rule{Int},ConstantModel{Number}}}(phi,1)
@test rmodel_number == Rule{Number,Union{Rule{Number},ConstantModel{Int}}}(phi,1)

@test_nowarn Rule{Number,ConstantModel{<:Number}}(phi,1)
@test_nowarn Rule{Number,Union{ConstantModel{Int},ConstantModel{Float64}}}(phi,1)

rfloat_number = @test_nowarn Rule{Float64,Union{Rule{Float64},ConstantModel{Float64}}}(phi,1.0)

@test_broken Rule{Number,Union{Rule{Number},ConstantModel{Number}}}(phi, rfloat_number)
r = @test_nowarn Rule{Number,Union{Rule{Number},ConstantModel{Number}}}(phi,rmodel_number)
r = @test_nowarn Rule{Number,Union{Rule{Number},ConstantModel{Number}}}(phi,r)
r = @test_nowarn Rule{Number,Union{Rule{Number},ConstantModel{Number}}}(phi,r)

@test outcometype(r) == Number
@test output_type(r) == Union{Nothing,Number}

default_consequent = cmodel_integer

# TODO from here

rules = @test_nowarn [Rule(phi, cmodel_integer), Rule(phi, cmodel_float), Rule{Float64,Union{Rule{Float64},ConstantModel{Float64}}}(phi,Rule{Float64,Union{Rule{Float64},ConstantModel{Float64}}}(phi,cmodel_float))]
dlmodel = @test_nowarn DecisionList(rules, default_consequent)
@test output_type(dlmodel) == Union{Float64,Int}

rules = @test_nowarn [Rule(phi, cmodel_integer), Rule(phi, cmodel_integer)]
dlmodel = @test_nowarn DecisionList(rules, default_consequent)
@test output_type(dlmodel) == Int

bmodel = @test_nowarn Branch(phi, DecisionList(rules, default_consequent), DecisionList(rules, default_consequent))
@test output_type(bmodel) == Int

bmodel_mixed = @test_broken Branch{Union{Float64,Int}}(phi, r, DecisionList(rules, default_consequent))
bmodel_mixed = @test_broken Branch(phi, r, DecisionList(rules, default_consequent))
@test_broken output_type(bmodel_mixed) == Union{Float64,Int}

@test_nowarn [print_model(buf, r) for r in rules];
@test_nowarn print_model(buf, dlmodel);
@test_nowarn print_model(buf, bmodel);

@test_nowarn Branch(phi,(bmodel,bmodel))
@test_broken bmodel_2 = Branch(phi,(bmodel,rfloat_number))
@test_broken bmodel_2 = Branch(phi,(dlmodel,rmodel))
bmodel_2 = @test_nowarn Branch(phi,(dlmodel,bmodel))
@test_nowarn print_model(buf, bmodel_2);
rcmodel = SoleModels.RuleCascade([phi,phi,phi], cmodel_integer)
@test_nowarn print_model(buf, Branch(phi, rcmodel, bmodel_2));


formula_p = SoleLogics.build_tree("p")
formula_q = SoleLogics.build_tree("q")
formula_r = SoleLogics.build_tree("r")
formula_s = SoleLogics.build_tree("s")

branch_q = @test_nowarn Branch(formula_q,("yes","no"),(;))
branch_s = @test_nowarn Branch(formula_s,("yes","no"),(;))
branch_r = @test_nowarn Branch(formula_r,(branch_s,"yes"),(;))

# dtmodel = DecisionTree(branch_r, (;))
# msmodel = MixedSymbolicModel(dtmodel)
