/*##############################################################################
## HPCC SYSTEMS software Copyright (C) 2016 HPCC Systems®.  All rights reserved.
############################################################################## */

// Test the triangular solver.  Can be left or right, and transposed.
IMPORT $.^ as PBblas;
IMPORT PBblas.internal as int;
IMPORT PBblas.MatUtils;
IMPORT PBblas.Types;
IMPORT int.Types as iTypes;
IMPORT Std.BLAS;
IMPORT $ as Tests;
IMPORT Tests.MakeTestMatrix as tm;

matrix_t := iTypes.matrix_t;
Triangle := Types.Triangle;
Diagonal := Types.Diagonal;
Upper  := Triangle.Upper;
Lower  := Triangle.Lower;
Layout_Part := iTypes.Layout_Part;
Side := Types.Side;

// Override BlockDimensions defaults to allow test with smaller matrixes
max_partition_size_or := 1000;
override := #STORED('BlockDimensions_max_partition_size', max_partition_size_or);

// TEST 1 -- Basic functionality with single partition (small matrix)

// Note:  For solve, only two dimensions are needed
// For solve AX, A is N x N and B/X is N x M
// For solve XA, B/X is M x N and A is N x N
N1 := 9;  // 9 x 9  should give a single partition
M1 := 9;

PreA1 := tm.Random(N1, N1, 1.0, 1);
A1 := PBblas.gemm(TRUE, FALSE, 1.0,
             PreA1, PreA1);    // Make a positive definite symmetric matrix of full rank
X1 := tm.Random(N1, M1, 1.0, 1);
// Calculate the transpose of X to use for XA testing
X1_T := MatUtils.Transpose(X1);
// E computes the B value for AX (i.e. AX).  Solving for AX = E should return X
E1 := PBblas.gemm(FALSE, FALSE, 1.0,
             A1, X1);
// F computes the B value for XA (i.e. X**TA).  Solving for XA = F should return X**T
F1 := PBblas.gemm(FALSE, FALSE, 1.0,
             X1_T, A1);


// Solve AX using Cholesky factorization
C_L1 := PBblas.potrf(Lower, A1);
C_S1 := PBblas.trsm(Side.Ax, Lower, FALSE, Diagonal.NotUnitTri,
                      1.0, C_L1, E1);
C_T1 := PBblas.trsm(Side.Ax, Upper, TRUE, Diagonal.NotUnitTri,
                      1.0, C_L1, C_S1);
test_11 := Tests.DiffReport.Compare_Cells('TEST1_1 -- Ax Single, Cholesky', X1, C_T1);

// Solve AX using LU factorization
E_LU1:= PBBlas.getrf(A1);
E_S1 := PBblas.trsm(Side.Ax, Lower, FALSE, Diagonal.UnitTri,
                      1.0, E_LU1, E1);
E_T1 := PBblas.trsm(Side.Ax, Upper, FALSE, Diagonal.NotUnitTri,
                      1.0, E_LU1, E_S1);
test_12 := Tests.DiffReport.Compare_Cells('TEST1_2 -- Ax Single, LU', X1, E_T1);

// Solve XA using LU
F_LU1:= E_LU1;
F_S1 := PBblas.trsm(Side.xA, Upper, FALSE, Diagonal.NotUnitTri,
                      1.0, F_LU1, F1);
F_T1 := PBblas.trsm(Side.xA, Lower, FALSE, Diagonal.UnitTri,
                      1.0, F_LU1, F_S1);
test_13:=Tests.DiffReport.Compare_Cells('TEST1_3 -- xA Single, LU', X1_T, F_T1);

// Note: Detailed comments omitted on subsequent tests as they all follow the same pattern


// TEST 2 --  Larger Matrix -- 4 partitions (2 x 2)
// Use a matrix size large enough, and max_partition_size small enough so that substantial
// partitioning occurs.
// 
N2 := 51;   // 51 should give A 4 partitions (2 x 2)
M2 := 67;

PreA2 := tm.RandomPersist(N2, N2, 1.0, 2, 'PA2');
A2 := PBblas.gemm(TRUE, FALSE, 1.0,
             PreA2, PreA2);    // Make a positive definite symmetric matrix of full rank
X2 := tm.RandomPersist(N2, M2, 1.0, 2, 'X2');
X2_T := MatUtils.Transpose(X2);

E2 := PBblas.gemm(FALSE, FALSE, 1.0,
             A2, X2);
F2 := PBblas.gemm(FALSE, FALSE, 1.0,
             X2_T, A2);

C_L2 := PBblas.potrf(Lower, A2);
C_S2 := PBblas.trsm(Side.Ax, Lower, FALSE, Diagonal.NotUnitTri,
                      1.0, C_L2, E2);
C_T2 := PBblas.trsm(Side.Ax, Upper, TRUE, Diagonal.NotUnitTri,
                      1.0, C_L2, C_S2);
test_21 := Tests.DiffReport.Compare_Cells('TEST2_1 -- Ax 2 x 2, Cholesky', X2, C_T2);

E_LU2:= PBBlas.getrf(A2);
E_S2 := PBblas.trsm(Side.Ax, Lower, FALSE, Diagonal.UnitTri,
                      1.0, E_LU2, E2);
E_T2 := PBblas.trsm(Side.Ax, Upper, FALSE, Diagonal.NotUnitTri,
                      1.0, E_LU2, E_S2);
test_22 := Tests.DiffReport.Compare_Cells('TEST2_1 -- Ax 2 x 2, LU', X2, E_T2);
//
F_LU2:= E_LU2;
F_S2 := PBblas.trsm(Side.xA, Upper, FALSE, Diagonal.NotUnitTri,
                      1.0, F_LU2, F2);
F_T2 := PBblas.trsm(Side.xA, Lower, FALSE, Diagonal.UnitTri,
                      1.0, F_LU2, F_S2);
test_23:=Tests.DiffReport.Compare_Cells('TEST2_3 -- xA 2 x 2, LU', X2_T, F_T2);

// TEST 3 -- Myriad
// Combine the small matrixes from Test 1 with the large from Test 2 to solve both simultaneously.

// Skip the Cholesky factorization from here on -- we already demonstrated it working -- to 
// allow more variation on A.

C_S3 := PBblas.trsm(Side.Ax, Lower, FALSE, Diagonal.NotUnitTri,
                      1.0, C_L2 + C_L1, E1 + E2);
C_T3 := PBblas.trsm(Side.Ax, Upper, TRUE, Diagonal.NotUnitTri,
                      1.0, C_L1 + C_L2, C_S3);
C_T3_1 := C_T3(wi_id = 1);
C_T3_2 := C_T3(wi_id = 2);

test_31 := Tests.DiffReport.Compare_Cells('TEST3_1 -- Ax Partitioned+Myr(1), Cholesky', X1, C_T3_1);
test_32 := Tests.DiffReport.Compare_Cells('TEST3_2 -- Ax Partitioned+Myr(2), Cholesky', X2, C_T3_2);

E_LU3:= E_LU2 + E_LU1; 
E_S3 := PBblas.trsm(Side.Ax, Lower, FALSE, Diagonal.UnitTri,
                      1.0, E_LU3, E1 + E2);
E_T3 := PBblas.trsm(Side.Ax, Upper, FALSE, Diagonal.NotUnitTri,
                      1.0, E_LU3, E_S3);
E_T3_1 := E_T3(wi_id = 1);
E_T3_2 := E_T3(wi_id = 2);                      
test_33 := Tests.DiffReport.Compare_Cells('TEST3_3 -- Ax Partitioned+Myr(2)_1, LU', X1, E_T3_1);
test_34 := Tests.DiffReport.Compare_Cells('TEST3_4 -- Ax Partitioned+Myr(2)_2, LU', X2, E_T3_2);
//
F_LU3 := E_LU3;
F_S3 := PBblas.trsm(Side.xA, Upper, FALSE, Diagonal.NotUnitTri,
                      1.0, F_LU1 + F_LU2, F1 + F2);
F_T3 := PBblas.trsm(Side.xA, Lower, FALSE, Diagonal.UnitTri,
                      1.0, F_LU1 + F_LU2, F_S3);
F_T3_1 := F_T3(wi_id = 1);
F_T3_2 := F_T3(wi_id = 2);   
test_35 := Tests.DiffReport.Compare_Cells('TEST3_5 -- xA Partitioned+Myr(2)_1, LU', X1_T, F_T3_1);
test_36 := Tests.DiffReport.Compare_Cells('TEST3_6 -- xA Partitioned+Myr(2)_2, LU', X2_T, F_T3_2);                      

// TEST 4 -- Larger 3 x 3 matrix
N4 := 71;  // Should give us 9 A partitions (3 x 3)
M4 := 70;

// Make A sparse (30%) to mix it up
PreA4 := tm.Random(N4, N4, .3, 4);
A4 := PBblas.gemm(TRUE, FALSE, 1.0,
             PreA4, PreA4);    // Make a positive definite symmetric matrix of full rank
X4 := tm.Matrix(N4, M4, 1.0, 4);
X4_T := MatUtils.Transpose(X4);
E4 := PBblas.gemm(FALSE, FALSE, 1.0,
             A4, X4);
F4 := PBblas.gemm(FALSE, FALSE, 1.0,
			 X4_T, A4);
E_LU4:= PBBlas.getrf(A4);

E_S4 := PBblas.trsm(Side.Ax, Lower, FALSE, Diagonal.UnitTri,
                      1.0, E_LU4, E4);
Solve_41 := PBblas.trsm(Side.Ax, Upper, FALSE, Diagonal.NotUnitTri,
                      1.0, E_LU4, E_S4);
test_41 := Tests.DiffReport.Compare_Cells('TEST4_1 -- Ax 3 x 3', X4, Solve_41);

F_LU4:= E_LU4;
F_S4 := PBblas.trsm(Side.xA, Upper, FALSE, Diagonal.NotUnitTri,
                      1.0, F_LU4, F4);
Solve_42 := PBblas.trsm(Side.xA, Lower, FALSE, Diagonal.UnitTri,
                      1.0, F_LU4, F_S4);
test_42 := Tests.DiffReport.Compare_Cells('TEST4_2 -- xA 3 x 3', X4_T, Solve_42);
        
// TEST 5 -- Myriad 2
// Test Ax with four simultaneous work-items using matrices of varying shape.                        

N5 := 107;  // Should give us 16 partitions (4 x 4)
M5 := 83;

A5 := tm.RandomPersist(N5, N5, 1.0, 5, 'A5'); 

// Make X sparse (70%) to mix it up
X5 := tm.RandomPersist(N5, M5, .7, 5, 'X5');
X5_T := MatUtils.Transpose(X5);
E5 := PBblas.gemm(FALSE, FALSE, 1.0,
             A5, X5);
F5 := PBblas.gemm(FALSE, FALSE, 1.0,
             X5_T, A5);
E_LU5:= PBBlas.getrf(A5);

E_S5 := PBblas.trsm(Side.Ax, Lower, FALSE, Diagonal.UnitTri,
                      1.0, E_LU5 + E_LU4 + E_LU2 + E_LU1, E1 + E2 + E4 + E5);
Solve_5 := PBblas.trsm(Side.Ax, Upper, FALSE, Diagonal.NotUnitTri,
                      1.0, E_LU1 + E_LU2 + E_LU4 + E_LU5, E_S5);
Solve_5_1 := Solve_5(wi_id=1);
test_51 := Tests.DiffReport.Compare_Cells('TEST5_1 -- Ax Myriad(4)_1', X1, Solve_5_1);             
Solve_5_2 := Solve_5(wi_id=2);
test_52 := Tests.DiffReport.Compare_Cells('TEST5_2 -- Ax Myriad(4)_2', X2, Solve_5_2);     
Solve_5_4 := Solve_5(wi_id=4);
test_54 := Tests.DiffReport.Compare_Cells('TEST5_4 -- Ax Myriad(4)_4', X4, Solve_5_4);
Solve_5_5 := Solve_5(wi_id=5);
test_55 := Tests.DiffReport.Compare_Cells('TEST5_5 -- Ax Myriad(4)_5', X5, Solve_5_5);

// TEST 6 -- Same as test 5, but for xA

F_LU5:= E_LU5;
F_S6 := PBblas.trsm(Side.xA, Upper, FALSE, Diagonal.NotUnitTri,
                      1.0, F_LU5 + F_LU4 + F_LU2 + F_LU1, F1 + F2 + F4 + F5);
Solve_6 := PBblas.trsm(Side.xA, Lower, FALSE, Diagonal.UnitTri,
                      1.0, F_LU1 + F_LU2 + F_LU4 + F_LU5, F_S6);
Solve_6_1 := Solve_6(wi_id=1);
test_61 := Tests.DiffReport.Compare_Cells('TEST6_1 -- xA Myriad(4)_1', X1_T, Solve_6_1);             
Solve_6_2 := Solve_6(wi_id=2);
test_62 := Tests.DiffReport.Compare_Cells('TEST6_2 -- xA Myriad(4)_2', X2_T, Solve_6_2);     
Solve_6_4 := Solve_6(wi_id=4);
test_64 := Tests.DiffReport.Compare_Cells('TEST6_4 -- xA Myriad(4)_4', X4_T, Solve_6_4);
Solve_6_5 := Solve_6(wi_id=5);
test_65 := Tests.DiffReport.Compare_Cells('TEST6_5 -- xA Myriad(4)_5', X5_T, Solve_6_5);

// TEST 7 -- Ax -- Use A2 and A5 to mix it up, and use alpha and transpose to cover the rest of the
//           features.
alpha := 1.0;
transA := FALSE;

A7 := A2 + A5;
X7 := X2 + X5;

// Compute B = AX
E7 := PBblas.gemm(FALSE, FALSE, 1.0,
			 A7, X7);
// Factor A
E_LU7 := PBblas.getrf(A7);

// Scale B by alpha
E7_s := PBblas.scal(alpha, E7);
// Transpose A
E_LU7_t := IF(transA, MatUtils.Transpose(E_LU7), E_LU7);

// Solve for original X by transposing A_factored**T and dividing B by alpha.
E_S7 := PBblas.trsm(Side.Ax, Lower, transA, Diagonal.UnitTri,
                      1/alpha, E_LU7_t, E7_s);
Solve_7 := PBblas.trsm(Side.Ax, Upper, transA, Diagonal.NotUnitTri,
                      1.0, E_LU7_t, E_S7);
Solve_7_2 := Solve_7(wi_id=2);
Solve_7_5 := Solve_7(wi_id=5);
// Verify that the result equals the original X
test_72 := Tests.DiffReport.Compare_Cells('TEST7_2 -- Ax Myr+alpha+trans', X2, Solve_7_2);
test_75 := Tests.DiffReport.Compare_Cells('TEST7_5 -- Ax Myr+alpha+trans', X5, Solve_7_5);

// TEST 8 -- xA -- Same as TEST 7 except solving for XA
 
F_LU8_t := E_LU7_t;

// Compute B = XA
F8 := PBblas.gemm(FALSE, FALSE, 1.0,
             X2_T + X5_T, A2 + A5);
F8_s := PBblas.scal(alpha, F8);
// Solve for original X by transposing A_factored**T and dividing B by alpha.
F_S8 := PBblas.trsm(Side.xA, Upper, transA, Diagonal.NotUnitTri,
                      1/alpha, F_LU8_t, F8_s);
Solve_8 := PBblas.trsm(Side.xA, Lower, transA, Diagonal.UnitTri,
                      1.0, F_LU8_t, F_S8);
Solve_8_2 := Solve_8(wi_id=2);
Solve_8_5 := Solve_8(wi_id=5);
test_82 := Tests.DiffReport.Compare_Cells('TEST8_2 -- xA Myr+alpha+trans', X2_T, Solve_8_2);
test_85 := Tests.DiffReport.Compare_Cells('TEST8_5 -- xA Myr+alpha+trans', X5_T, Solve_8_5);

// TEST 9 -- Safety test -- Compare PB_Blas results with Blas results, using alpha and
//           transpose
// Use Matrix from Test 5.   It is asymmetrical.
E5_alpha := PBblas.scal(alpha, E5);
E_LU5_t  := IF(transA, MatUtils.Transpose(E_LU5), E_LU5);
// Run Ax solve using BLAS with alpha and transpose
E5_set := int.MakeR8Set(N5, M5, 1, 1, E5_alpha);
LU5_set := int.MakeR8Set(N5, N5, 1, 1, E_LU5_t);
blas_S1 := BLAS.dtrsm(Side.Ax, Lower, transA, Diagonal.UnitTri,
                                  N5,
                                  M5,
                                  N5,
                                  1/alpha, LU5_set, E5_set);
                                  
blas_S2 := BLAS.dtrsm(Side.Ax, Upper, transA, Diagonal.NotUnitTri,
                                  N5,
                                  M5,
                                  N5,
                                  1.0, LU5_set, blas_S1
                                  );
// Do the same solve for PBblas
S1 := PBblas.trsm(Side.Ax, Lower, transA, Diagonal.UnitTri,
                      1/alpha, E_LU5_t, E5_alpha);
S2 := PBblas.trsm(Side.Ax, Upper, transA, Diagonal.NotUnitTri,
                      1.0, E_LU5_t, S1);             
blas_cells := int.FromR8Set(blas_S2, N5);
blas_S1_cells := int.FromR8Set(blas_S1, N5);

test_91 := Tests.DiffReport.Compare_Cells('TEST9_1 -- Ax Blas vs X5',blas_cells, X5);
test_92 := Tests.DiffReport.Compare_Cells('TEST9_2 -- Ax PB_Blas vs X5',S2, X5);
test_93 := Tests.DiffReport.Compare_Cells('TEST9_3 -- Ax PB_Blas vs blas ',S2, blas_cells);
test_94 := Tests.DiffReport.Compare_Cells('TEST9_4 -- Ax S1 vs Blas_S1 ',S1, blas_S1_cells);

// Now the same for XA
F_LU5_t := E_LU5_t;
F5_alpha := PBblas.scal(alpha, F5);
// Run xA solve using BLAS with alpha and transpose
F5_set := int.MakeR8Set(M5, N5, 1, 1, F5_alpha);
blas_S1_2 := BLAS.dtrsm(Side.xA, Upper, transA, Diagonal.NotUnitTri,
                                  M5,
                                  N5,
                                  N5,
                                  1/alpha, LU5_set, F5_set);
                                  
blas_S2_2 := BLAS.dtrsm(Side.xA, Lower, transA, Diagonal.UnitTri,
                                  M5,
                                  N5,
                                  N5,
                                  1.0, LU5_set, blas_S1_2
                                  );
// Do the same solve for PBblas
S1_2 := PBblas.trsm(Side.xA, Upper, transA, Diagonal.NotUnitTri,
                      1/alpha, F_LU5_t, F5_alpha);
S2_2 := PBblas.trsm(Side.xA, Lower, transA, Diagonal.UnitTri,
                      1.0, F_LU5_t, S1_2);             
blas_cells_2 := int.FromR8Set(blas_S2_2, M5);
blas_S1_cells_2 := int.FromR8Set(blas_S1_2, M5);

test_95 := Tests.DiffReport.Compare_Cells('TEST9_5 -- xA Blas vs X5',blas_cells_2, X5_T);
test_96 := Tests.DiffReport.Compare_Cells('TEST9_6 -- xA PB_Blas vs X5',S2_2, X5_T);
test_97 := Tests.DiffReport.Compare_Cells('TEST9_7 -- xA PB_Blas vs blas ',S2_2, blas_cells_2);
test_98 := Tests.DiffReport.Compare_Cells('TEST9_9 -- xA S1 vs Blas_S1 ',S1_2, blas_S1_cells_2);

result  := SORT(test_11 + test_12 + test_13
               + test_21 + test_22 + test_23
               + test_31 + test_32 + test_33 + test_34 + test_35 + test_36
               + test_41 + test_42
               + test_51 + test_52 + test_54 + test_55
               + test_61 + test_62 + test_64 + test_65
               + test_72 + test_75
               + test_82 + test_85
               + test_91 + test_92 + test_93 + test_94 
               + test_95 + test_96 + test_97 + test_98, TestName);
//result := SORT(test_91 + test_92 + test_93 + test_94 + test_95 + test_96 + test_97 + test_98, TestName); //C_S4;
//result := test_91;
EXPORT Solve := WHEN(result, override);
