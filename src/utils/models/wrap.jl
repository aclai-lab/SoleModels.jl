wrap(o::O) where {O} = convert(ConstantModel{O}, o)

wrap(o::Function) = FunctionModel(o)
wrap(o::FunctionWrapper{O}) where {O} = FunctionModel{O}(o)
