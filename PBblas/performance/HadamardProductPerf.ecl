/*##############################################################################
## HPCC SYSTEMS software Copyright (C) 2016 HPCC Systems®.  All rights reserved.
############################################################################## */
IMPORT $.^ as PBblas;
IMPORT PBblas.test as Tests;
IMPORT PBblas.internal as int;
IMPORT int.MatDims as md;
IMPORT PBblas.Types;
IMPORT int.Types as iTypes;
IMPORT Tests.MakeTestMatrix as tm;
IMPORT Tests.DiffReport as dr;

Layout_Cell := Types.Layout_Cell;
Layout_Dims := iTypes.Layout_Dims;

N1 := 100000;
M1 := 10000;
//N1 := 500;
//M1 := 200;
mat1 := tm.MatrixPersist(N1, M1, 1.0, 1);
mat1_size := N1 * M1;
dims := DATASET([{'X', 1, N1, M1},
					{'Y', 1, N1, M1}], Layout_Dims);
// To keep the test simple, just square each matrix (i.e. hadamard multiply by itself)
newmat := PBblas.HadamardProduct(mat1, mat1);
//newmat := PBblas.HadamardProduct_p(mat1, mat1, dims);


EXPORT HadamardProductPerf := COUNT(newmat);
