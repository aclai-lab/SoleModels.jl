using DataFrames
using SoleLogics
using SoleModels
using Tables
import SoleLogics: LogicalInstance
import SoleModels: PropositionalLogiset, alphabetlogiset
# alphabetlogiset(dataset)=> atomsf

df = DataFrame([[1,2,3], [2,3,4]], :auto)
mat = [ 1 2 3; 4 5 6];

proplog = PropositionalLogiset(df)
al = SoleModels.alphabetlogiset(proplog) 
# first instance of proplog
instance1 = LogicalInstance(proplog, 1)



interpret(al[2][2], instance1)