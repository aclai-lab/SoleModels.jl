using DataFrames
using SoleModels
using SoleLogics
import SoleLogics: LogicalInstance
import SoleModels: PropositionalLogiset, TestOperator, BoundedScalarConditions


# import SoleModels: syntaxstring

df = (DataFrame([[1,2,3], [2,3,4]], :auto))
pl = SoleModels.PropositionalLogiset(df)






# alphabetlogiset(dataset)=> atomsf
