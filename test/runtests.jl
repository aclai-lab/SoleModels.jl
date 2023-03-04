# using Revise
using SoleLogics
using SoleModels
using SoleModels: ConstantModel
using Test

using SoleLogics
using Test
using Random

function run_tests(list)
    println("\n" * ("#"^50))
    for test in list
        println("TEST: $test")
        include(test)
    end
end

println("Julia version: ", VERSION)

test_suites = [
    ("Base", ["base.jl", ]),
    ("Misc", ["misc.jl", ]),
]

@testset "SoleModels.jl" begin
    for ts in eachindex(test_suites)
        name = test_suites[ts][1]
        list = test_suites[ts][2]
        let
            @testset "$name" begin
                run_tests(list)
            end
        end
    end
    println()
end
