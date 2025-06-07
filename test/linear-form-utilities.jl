b = Branch(LeftmostConjunctiveForm((@atoms p q r s)), "YES", "NO")

@test_nowarn b[1:3]
@test_nowarn b[[1]]
@test_nowarn b[1]

@test b[1:3] isa LeftmostConjunctiveForm
@test b[[1]] isa LeftmostConjunctiveForm
@test b[1] isa Atom
@test b[1] isa SoleLogics.AbstractAtom
