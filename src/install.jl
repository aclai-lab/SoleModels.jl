# This file can be used to automatically resolve dependencies
# involving unregistered packages.
# To do so, simply call `install` one time for each package
# respecting the correct dependency order.

using Pkg

# Remove the specified package (do not abort if it is already removed) and reinstall it.
function install(package::String, url::String, rev::Union{Nothing,String} = nothing)
    printstyled(stdout, "\nRemoving: $package\n", color=:green)
    try
        Pkg.rm(package)
    catch error
        println(); showerror(stdout, error); println()
    end

    printstyled(stdout, "\nFetching: $url at branch $rev\n", color=:green)
    try
        if !isnothing(rev)
            Pkg.add(url=url, rev=rev)
        else
            Pkg.add(url=url)
        end

        printstyled(stdout, "\nPackage $package instantiated correctly\n", color=:green)
    catch error
        println(); showerror(stdout, error); println()
    end
end

install("SoleBase", "https://github.com/aclai-lab/SoleBase.jl", "dev-v0.9.1")
install("SoleData", "https://github.com/aclai-lab/SoleData.jl", "dev-v0.9.1")
# install("SoleLogics", "https://github.com/aclai-lab/SoleLogics.jl", "dev-v0.9.1")
install("SoleLogics", "../SoleLogics.jl")

Pkg.instantiate()
