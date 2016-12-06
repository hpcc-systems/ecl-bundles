/*##############################################################################
## HPCC SYSTEMS software Copyright (C) 2016 HPCC Systems®.  All rights reserved.
############################################################################## */
IMPORT $ as Tests;
IMPORT $.^ as PBblas;
IMPORT PBblas.internal as int;
IMPORT int.MatDims as md;
IMPORT PBblas.Types;
IMPORT Tests.MakeTestMatrix as tm;
IMPORT Tests.DiffReport as dr;

Layout_Cell := Types.Layout_Cell;

max_part_size_or := 1000;
nodes_or := 20;
N1 := 100;
M1 := 100;

mat1 := tm.Matrix(N1, M1, .9, 1);
mat2 := tm.Matrix(M1, N1, .7, 2);
mat1_size := N1 * M1;
mat2_size := M1 * N1;

// To keep the test simple, just square each matrix (i.e. hadamard multiply by itself)
newmat := PBblas.HadamardProduct(mat1+mat2, mat1+mat2);

// Now validate the cells to make sure the values are correct.
// Just use work item 2 to simplify the test
newmat2 := SORT(newmat(wi_id = 2), x, y);

Layout_Cell square(Layout_Cell lr) := TRANSFORM
  orig := lr.v;
  squared := orig * orig;
  SELF.v := squared;
  SELF := lr;
  
END;

mat2squared := PROJECT(mat2, square(LEFT));

result := dr.Compare_Cells('HadamardProduct Test1', newmat2, mat2squared);

EXPORT HadamardProduct := result;
