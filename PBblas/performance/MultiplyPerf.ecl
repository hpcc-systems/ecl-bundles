/*##############################################################################
## HPCC SYSTEMS software Copyright (C) 2016 HPCC Systems®.  All rights reserved.
############################################################################## */
/**
  * Performance test for multiplication.  Performs a large myriad multiply
  * operation to observer performance.
  */

IMPORT $.^ as PBblas;
IMPORT PBblas.internal as int;
IMPORT int.Types as iTypes;
IMPORT PBblas.Types;
IMPORT int.MatDims;
IMPORT PBblas.test as Tests;
IMPORT Tests.MakeTestMatrix as tm;

Layout_Cell := Types.Layout_Cell;
Layout_Part := iTypes.Layout_Part;

// Test configuration Parameters -- modify these to vary the testing

N := 100000;   // Number of rows in A matrix and result
M := 10000;      // Number of columns in A matrix and rows in B matrix
P := 10000; // Number of columns in B matrix and result

density := 1.0; // 1.0 is fully dense. 0.0 is empty.
// End of config parameters

// Generate test data for A and B matrixes in the cell form

// Setup to make calls to PB_dgemm
a_dat1 := tm.MatrixPersist(N, M, density, 1, 'A1');
a_dat2 :=  tm.MatrixPersist(M, N, density, 2, 'A2');
b_dat1 := tm.MatrixPersist(M, P, density, 1, 'B1');
b_dat2 :=  tm.MatrixPersist(N, P, density, 2, 'B2');
a_dat := a_dat1 + a_dat2;
b_dat := b_dat2 + b_dat1;
//a_dat := a_dat1;
//b_dat := b_dat1;
a_cells := DISTRIBUTE(a_dat);
b_cells := DISTRIBUTE(b_dat);

// Make an empty C matrix
c_cells := DATASET([], Layout_Cell);

cell_results := PBblas.gemm(FALSE, False, 1.0, a_cells, b_cells);

EXPORT MultiplyPerf := COUNT(cell_results);

