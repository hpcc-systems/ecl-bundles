/*##############################################################################
## HPCC SYSTEMS software Copyright (C) 2016 HPCC Systems®.  All rights reserved.
############################################################################## */

IMPORT $.^ as PBblas;
IMPORT PBblas.internal as int;
IMPORT int.Types as iTypes;
IMPORT $ as Tests;
IMPORT Tests.MakeTestMatrix as tm;
IMPORT PBblas.Types;
IMPORT Tests.DiffReport as dr;
IMPORT Std.BLAS;
tri := Types.triangle;
Layout_Cell := Types.Layout_Cell;
matrix_t := iTypes.matrix_t;
diag := Types.diagonal;

// Override BlockDimensions default so we can test with small matrixes
max_partition_size_or := 1000;
override := #STORED('BlockDimensions_max_partition_size', max_partition_size_or);
 
// Test 1 -- Basic, No partitioning
N1 := 9;
M1 := 9;

// Create a test matrix
preA1 := tm.Random(N1, M1, 1.0, 1);

// Multiply A**T * A to create square matrix
A1 := PBblas.gemm(FALSE, TRUE, 1.0, preA1, preA1);

// Call PB_dgetrf
A1_factored := PBblas.getrf(A1);

// Extract upper and lower triangles
U1 := PBblas.ExtractTri(tri.Upper, diag.NotUnitTri, A1_factored);
L1 := PBblas.ExtractTri(tri.Lower, diag.UnitTri, A1_factored);

// Multiply L * U, and compare with original square.
cmp1 := PBblas.gemm(FALSE, FALSE, 1.0, L1, U1);

test1 := dr.Compare_Cells('TEST1 -- LU L1U1', A1, cmp1);

// TEST 2 -- Partitioned Matrix
N2 := 40;
M2 := 40;

preA2 := tm.Random(N2, M2, 1.0, 2);

// Make square
A2 := PBblas.gemm(FALSE, TRUE, 1.0, preA2, preA2);

// Factor and extract L and U.
A2_factored := PBblas.getrf(A2);
U2 := PBblas.ExtractTri(tri.Upper, diag.NotUnitTri, A2_factored);
L2 := PBblas.ExtractTri(tri.Lower, diag.UnitTri, A2_factored);

// Multiply L * U, and we should get the original square matrix
cmp2 := PBblas.gemm(FALSE, FALSE, 1.0, L2, U2);
U2_r8s := int.MakeR8Set(N2, M2, 1, 1, U2);
L2_r8s := int.MakeR8Set(N2, M2, 1, 1, L2);
cmp2_r8s :=BLAS.dgemm(FALSE, FALSE, N2,M2,M2,1.0, L2_r8s, U2_r8s, 0);
cmp2_nb := int.FromR8Set(cmp2_r8s, N2);

test2 := dr.Compare_Cells('TEST2 -- LU Partitioned L2U2', A2, cmp2);

// TEST 3 -- Myriad basic test.  Solve 1 and 2 at the same time
A3 := A1 + A2; // 2 different work-items
A3_factored := PBblas.getrf(A3);
U3 := PBblas.ExtractTri(tri.Upper, diag.NotUnitTri, A3_factored);
L3 := PBblas.ExtractTri(tri.Lower, diag.UnitTri, A3_factored);
// Multiply L * U, and we should get the original square matrices
cmp3 := PBblas.gemm(FALSE, FALSE, 1.0, L3, U3);
// Extract the two original matrices
cmp3_1 := cmp3(wi_id = 1);
cmp3_2 := cmp3(wi_id = 2);

test3_1 := dr.Compare_Cells('TEST3_1 -- LU Partitioned+Myriad A1+A2-1', A1, cmp3_1);
test3_2 := dr.Compare_Cells('TEST3_2 -- LU Partitioned+Myriad A1+A2-2', A2, cmp3_2);

// TEST4 -- Myriad variations -- Try with more and varied matrixes
//A1 -- Small  -- Single partition
//A2 -- Larger -- Many partitions even partition sizes
//A4 -- Large, Prime dimensions, uneven partition sizes
N4 := 87;
M4 := 31;
preA4 := tm.Random(N4, M4, 1.0, 4);

// Make square
A4 := PBblas.gemm(FALSE, TRUE, 1.0, preA4, preA4);
A4_All := A4 + A1 + A2;
A4_factored := PBblas.getrf(A4_All);
U4 := PBblas.ExtractTri(tri.Upper, diag.NotUnitTri, A4_factored);
L4 := PBblas.ExtractTri(tri.Lower, diag.UnitTri, A4_factored);
// Multiply L * U, and we should get the original square matrices
cmp4 := PBblas.gemm(FALSE, FALSE, 1.0, L4, U4);
// Extract the two original matrices
cmp4_1 := cmp4(wi_id = 1);
cmp4_2 := cmp4(wi_id = 2);
cmp4_4 := cmp4(wi_id = 4);

test4_1 := dr.Compare_Cells('TEST4_1 -- LU Partitioned+Myriad A1+A2+A4-1', A1, cmp4_1);
test4_2 := dr.Compare_Cells('TEST4_2 -- LU Partitioned+Myriad A1+A2+A4-2', A2, cmp4_2);
test4_3 := dr.Compare_Cells('TEST4_3 -- LU Partitioned+Myriad A1+A2+A4-4', A4, cmp4_4);

rslt := SORT(test1 + test2
               + test3_1 + test3_2
               + test4_1 + test4_2 + test4_3, TestName);

EXPORT getrf := WHEN(rslt, override);