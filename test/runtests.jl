# using Revise
using SoleLogics
using SoleModels
using SoleModels: ConstantModel
using Test

@testset "SoleModels.jl" begin
    
    buf = IOBuffer()

    p = SoleLogics.build_tree("p")
    phi = SoleLogics.build_tree("p∧q∨r")
    phi2 = SoleLogics.build_tree("q∧s→r")

    @test_nowarn ConstantModel(1,(;))
    @test_nowarn ConstantModel(1)
    @test_throws MethodError ConstantModel{Float64}(1,(;))

    const_any = "Hi there!"
    const_string = "Wow!"
    const_float = 1.0
    const_number = 1
    const_integer = 1

    cmodel_any = @test_nowarn ConstantModel{String}(const_any,(;))
    cmodel_string = @test_nowarn ConstantModel(const_string,(;))
    cmodel_float = @test_nowarn ConstantModel{Float64}(const_float,(;))
    cmodel_number = @test_nowarn ConstantModel{Number}(const_number,(;))
    cmodel_integer = @test_nowarn ConstantModel{Int}(const_integer)

    @test_throws MethodError convert(AbstractModel{<:Int}, cmodel_number)
    convert(AbstractModel{Int}, cmodel_number)

    r1 = @test_nowarn Rule(phi, cmodel_number)
    r2 = @test_nowarn Rule(phi, cmodel_integer)
    r3 = @test_nowarn Rule{Int}(phi, cmodel_number)
    r4 = @test_nowarn Rule{Int}(phi, cmodel_integer)

    @test_nowarn [cmodel_string, cmodel_any, cmodel_float, cmodel_number, cmodel_integer]
    @test_nowarn ConstantModel{String}[cmodel_string]
    @test_nowarn ConstantModel{String}[cmodel_string, cmodel_any]
    @test_nowarn ConstantModel{Int}[cmodel_number, cmodel_integer]
    @test_nowarn ConstantModel{Number}[cmodel_number, cmodel_integer]

    consts = @test_nowarn [const_any, const_string, const_float, const_number, const_integer]
    cmodels = @test_nowarn [cmodel_any, cmodel_string, cmodel_float, cmodel_number, cmodel_integer]
    cmodels_num = @test_nowarn [cmodel_float, cmodel_number, cmodel_integer]

    @test_nowarn [Rule(phi, c) for c in consts]
    @test_nowarn [Rule(phi, c) for c in cmodels]

    L = @test_nowarn Logic{:ModalLogic}

    rule1 = @test_nowarn Rule{Float64,L}(phi,const_float)
    rule1 = @test_nowarn Rule{Float64,L,Union{Rule{Float64},ConstantModel{Float64}}}(phi,const_float)

    # TODO create macro for shortened version of:
    # rule1_ = @test_nowarn Rule{Float64,L,Union{Rule,ConstantModel}}(phi,const_float)
    # @test rule1 == rule1_

    rule2 = @test_nowarn Rule(phi2, rule1)

    @test_nowarn [Rule{<:FinalOutcome}(phi, c) for c in cmodels]
    @test_nowarn [Rule{Number}(phi, c) for c in cmodels_num]
    @test_nowarn [Rule{Number}(phi, c) for c in cmodels_num]

    @test_nowarn Rule{Number,L}(phi,1)
    @test_nowarn Rule{Number,L,ConstantModel{Number}}(phi, 1)

    @test_nowarn Rule{Number,L,ConstantModel{Number}}(phi,1)
    @test_broken Rule{Number,L,ConstantModel{Int}}(phi, 1)
    @test_broken Rule{Int,L,ConstantModel{Number}}(phi, 1)
    @test_throws TypeError Rule{Int,L,ConstantModel{Number}}(phi, 1.0)

    rmodel_number = @test_nowarn Rule{Number,L,Union{Rule{Number},ConstantModel{Number}}}(phi,1)
    @test_broken Rule{Number,L,Union{Rule{Int},ConstantModel{Number}}}(phi,1)
    @test_broken Rule{Number,L,Union{Rule{Number},ConstantModel{Int}}}(phi,1)

    @test_broken Rule{Number,L,ConstantModel{<:Number}}(phi,1)
    @test_broken Rule{Number,L,Union{ConstantModel{Int},ConstantModel{Float64}}}(phi,1)

    rfloat_number = @test_nowarn Rule{Float64,L,Union{Rule{Float64},ConstantModel{Float64}}}(phi,1.0)

    @test_broken Rule{Number,L,Union{Rule{Number},ConstantModel{Number}}}(phi,rfloat_number)
    r = @test_nowarn Rule{Number,L,Union{Rule{Number},ConstantModel{Number}}}(phi,rmodel_number)
    r = @test_nowarn Rule{Number,L,Union{Rule{Number},ConstantModel{Number}}}(phi,r)
    r = @test_nowarn Rule{Number,L,Union{Rule{Number},ConstantModel{Number}}}(phi,r)

    @test outcome_type(r) == Number
    @test output_type(r) == Union{Nothing,Number}

    default_consequent = cmodel_integer

    rules = @test_nowarn [Rule(phi, cmodel_integer), Rule(phi, cmodel_float), Rule{Float64,L,Union{Rule{Float64},ConstantModel{Float64}}}(phi,Rule{Float64,L,Union{Rule{Float64},ConstantModel{Float64}}}(phi,cmodel_float))]
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
    @test_nowarn print_model(buf, Branch(phi, SoleModels.RuleCascade([phi,phi,phi], cmodel_integer), bmodel_2));
    

    formula_p = SoleLogics.build_tree("p")
    formula_q = SoleLogics.build_tree("q")
    formula_r = SoleLogics.build_tree("r")
    formula_s = SoleLogics.build_tree("s")

    branch_q = @test_nowarn Branch(formula_q,("yes","no"),(;))
    branch_s = @test_nowarn Branch(formula_s,("yes","no"),(;))
    branch_r = @test_nowarn Branch(formula_r,(branch_s,"yes"),(;))

end
