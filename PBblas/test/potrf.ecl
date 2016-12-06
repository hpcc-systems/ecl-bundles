/*##############################################################################
## HPCC SYSTEMS software Copyright (C) 2016 HPCC Systems®.  All rights reserved.
############################################################################## */
IMPORT $.^ as PBblas;
IMPORT $ as Tests;
IMPORT Tests.MakeTestMatrix as tm;
IMPORT PBblas.Types;
IMPORT PBblas.internal as int;
IMPORT int.Types as iTypes;
IMPORT Tests.DiffReport as dr;
tri := Types.triangle;
matrix_t := iTypes.matrix_t;

// Override BlockDimensions parameters to test with smaller matrixes
max_partition_size_or := 1000;
override := #STORED('BlockDimensions_max_partition_size', max_partition_size_or);

// TEST 1 -- Basic test, no partitioning
N1 := 8;
M1 := 10;

preA1 := tm.Random(N1, M1, 1.0, 1);

A1 := PBblas.gemm(FALSE, TRUE, 1.0, preA1, preA1);

U1 := PBblas.potrf(tri.Upper, A1);
L1 := PBblas.potrf(tri.Lower, A1);

L1U1 := PBblas.gemm(FALSE, FALSE, 1.0, L1, U1);
U1tU1 := PBblas.gemm(TRUE, FALSE, 1.0, U1, U1);
L1L1t := PBblas.gemm(FALSE, TRUE, 1.0, L1, L1);
U1tL1t := PBblas.gemm(TRUE, TRUE, 1.0, U1, L1);

test11 := dr.Compare_Cells('TEST1 -- Cholesky L1U1', A1, L1U1);
test12 := dr.Compare_Cells('TEST1 -- Cholesky U1TU1', A1, U1TU1);
test13 := dr.Compare_Cells('TEST1 -- Cholesky L1L1t', A1, L1L1t);
test14 := dr.Compare_Cells('TEST1 -- Cholesky U1tL1t', A1, U1tL1t);

// TEST 2 -- Larger, partitioned matrix
N2 := 50;
M2 := 70;

preA2 := tm.Random(N2, M2, 1.0, 2);

A2 := PBblas.gemm(FALSE, TRUE, 1.0, preA2, preA2);

U2 := PBblas.potrf(tri.Upper, A2);
L2 := PBblas.potrf(tri.Lower, A2);

L2U2 := PBblas.gemm(FALSE, FALSE, 1.0, L2, U2);
U2tU2 := PBblas.gemm(TRUE, FALSE, 1.0, U2, U2);
L2L2t := PBblas.gemm(FALSE, TRUE, 1.0, L2, L2);
U2tL2t := PBblas.gemm(TRUE, TRUE, 1.0, U2, L2);

test21 := dr.Compare_Cells('TEST2 -- Cholesky L2U2', A2, L2U2);
test22 := dr.Compare_Cells('TEST2 -- Cholesky U2TU2', A2, U2TU2);
test23 := dr.Compare_Cells('TEST2 -- Cholesky L2L2t', A2, L2L2t);
test24 := dr.Compare_Cells('TEST2 -- Cholesky U2tL2t', A2, U2tL2t);

// TEST 3 -- Partitioned + Myriad
U3 := PBblas.potrf(tri.Upper, A1 + A2);
L3 := PBblas.potrf(tri.Lower, A2 + A1);

L3U3 := PBblas.gemm(FALSE, FALSE, 1.0, L3, U3);
U3tU3 := PBblas.gemm(TRUE, FALSE, 1.0, U3, U3);
L3L3t := PBblas.gemm(FALSE, TRUE, 1.0, L3, L3);
U3tL3t := PBblas.gemm(TRUE, TRUE, 1.0, U3, L3);

L3U3_1 := L3U3(wi_id = 1);
L3U3_2 := L3U3(wi_id = 2);
U3tU3_1 := U3tU3(wi_id = 1);
U3tU3_2 := U3tU3(wi_id = 2);
L3L3t_1 := L3L3t(wi_id = 1);
L3L3t_2 := L3L3t(wi_id = 2);
U3tL3t_1 := U3tL3t(wi_id = 1);
U3tL3t_2 := U3tL3t(wi_id = 2);
test31 := dr.Compare_Cells('TEST3 -- Cholesky L3U3_1', A1, L3U3_1);
test32 := dr.Compare_Cells('TEST3 -- Cholesky U3TU2_1', A1, U3TU3_1);
test33 := dr.Compare_Cells('TEST3 -- Cholesky L3L3t_1', A1, L3L3t_1);
test34 := dr.Compare_Cells('TEST3 -- Cholesky U3tL3t_1', A1, U3tL3t_1);
test35 := dr.Compare_Cells('TEST3 -- Cholesky L3U3_2', A2, L3U3_2);
test36 := dr.Compare_Cells('TEST3 -- Cholesky U3TU2_2', A2, U3TU3_2);
test37 := dr.Compare_Cells('TEST3 -- Cholesky L3L3t_2', A2, L3L3t_2);
test38 := dr.Compare_Cells('TEST3 -- Cholesky U3tL3t_2', A2, U3tL3t_2);

rslt := SORT(test11 + test12 + test13 + test14
      + test21 + test22 + test23 + test24
      + test31 + test32 + test33 + test34 + test35 + test36 + test37 + test38, TestName);

EXPORT potrf := WHEN(rslt, override);