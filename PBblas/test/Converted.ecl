IMPORT $.^ as PBblas;
IMPORT PBblas.Types;
IMPORT ML_Core.Types as MlTypes;
IMPORT $ as Tests;
IMPORT Tests.MakeTestMatrix as tm;
IMPORT PBblas.Converted as conv;
IMPORT Tests.DiffReport as dr;

NumericField  := MlTypes.NumericField;
DiscreteField := MlTypes.DiscreteField;
Layout_Cell   := Types.Layout_Cell;
value_t       := Types.value_t;
dimension_t   := Types.dimension_t;

/**
  * Test for PBblas.Converted module.
  * Convert to and from ML_Core/Types Field formats and Layout_Cell
  *
  */
  
N := 1000;
M := 10;

// Create a random matrix
A := tm.Random(N, M, 1.0, 1);

// Convert to numeric field dataset
DN := conv.MatrixToNF(A);
// Convert to discrete field dataset
DD := conv.MatrixToDF(A);

// Convert numeric field back to matrix
numAcmp := conv.NFToMatrix(DN);
// Convert discrete field back to matrix
discAcmp := conv.DFToMatrix(DD);

// Create a version of A with values rounded to use to compare against
// discrete field data
value_t roundIt(value_t v, dimension_t r, dimension_t c) := ROUND(v);
discA := PBblas.Apply2Elements(A, roundIt);

// Compare the round trip results for numeric and discrete
test1 := dr.Compare_Cells('TEST1 -- Numeric Field', A, numAcmp);
test2 := dr.Compare_Cells('TEST2 -- Discrete Field', discA, discAcmp);

EXPORT Converted := test1 + test2;
