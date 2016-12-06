/*##############################################################################
## HPCC SYSTEMS software Copyright (C) 2016 HPCC Systems®.  All rights reserved.
############################################################################## */
IMPORT $.^ as PBblas;
IMPORT $ as Tests;
IMPORT $.^ as PBblas;
IMPORT PBblas.internal as int;
IMPORT int.MatDims as md;
IMPORT PBblas.Types;
IMPORT int.Types as iTypes;
IMPORT Tests.MakeTestMatrix as tm;
OpType := iTypes.OpType;

test_rec := RECORD
  STRING test;
  UNSIGNED errors;
  STRING details := '';
END;

// Override Block Dimensions defaults so we can test with smaller matrixes
max_part_size_or := 1000;
nodes_or := 3;
override1 := #STORED('BlockDimensions_max_partition_size', max_part_size_or);
override2 := #STORED('BlockDimensions_nodes', nodes_or);
override := SEQUENTIAL(override1, override2);


N1 := 100;
M1 := 100;
//N1 := 500;
//M1 := 200;
mat1 := tm.Matrix(N1, M1, .9, 1);
mat2 := tm.Matrix(M1, N1, .7, 2);
mat1_size := N1 * M1;
mat2_size := M1 * N1;

// TEST1 -- Basic Dimension Calc
dims1 := md.FromCells(mat1+mat2);
dims1_1 := dims1(wi_id = 1)[1];
dims1_2 := dims1(wi_id = 2)[1];
errs1_1 := IF(dims1_1.m_rows != N1 OR dims1_1.m_cols != M1, 1, 0);
errs1_2 := IF(dims1_2.m_rows != M1 OR dims1_2.m_cols != N1, 1, 0);
errs1 := errs1_1 + errs1_2;
test1 := DATASET([{'test1_1 -- Basic Dimensions', errs1_1},
                  {'test1_2 -- Basic Dimensions', errs1_2}], test_rec);

// TEST2 -- Basic Partitioning From Dims

pdims2 := md.PartitionedFromDims(dims1);
pdims2_1 := pdims2(wi_id = 1)[1];
pdims2_2 := pdims2(wi_id = 2)[1];
block_size2_1 := pdims2_1.block_rows * pdims2_1.block_cols;
block_size2_2 := pdims2_2.block_rows * pdims2_2.block_cols;
mat_size2_1 := pdims2_1.row_blocks * pdims2_1.col_blocks * block_size2_1;
mat_size2_2 := pdims2_2.row_blocks * pdims2_2.col_blocks * block_size2_2;
errs2_1 := IF(block_size2_1 > max_part_size_or OR mat_size2_1 < mat1_size, 1, 0);
errs2_2 := IF(block_size2_2 > max_part_size_or OR mat_size2_2 < mat2_size, 1, 0);
test2 := DATASET([{'test2_1 -- Basic Partitioning From Dims', errs2_1,
                     'row_blocks = ' + pdims2_1.row_blocks + ', col_blocks = ' + 
                     pdims2_1.col_blocks + ', block_rows = ' + pdims2_1.block_rows + 
                     ', block_cols = ' + pdims2_1.block_cols},
                  {'test2_2 -- Basic Partitioning From Dims', errs2_2}], test_rec);

// TEST 3 -- Basic Partitioning From Cells
pdims3 := md.PartitionedFromCells(mat1+mat2, 'A');
pdims3_1 := pdims3(wi_id = 1);
pdims3_2 := pdims3(wi_id = 2);
block_size3_1 := pdims3_1.block_rows * pdims3_1.block_cols;
block_size3_2 := pdims3_2.block_rows * pdims3_2.block_cols;
mat_size3_1 := pdims3_1.row_blocks * pdims3_1.col_blocks * block_size3_1;
mat_size3_2 := pdims3_2.row_blocks * pdims3_2.col_blocks * block_size3_2;
errs3_1 := IF(block_size3_1 > max_part_size_or OR mat_size3_1 < mat1_size, 1, 0);
errs3_2 := IF(block_size3_2 > max_part_size_or OR mat_size3_2 < mat2_size, 1, 0);
test3 := DATASET([{'test3_1 -- Basic Partitioning From Cells', errs2_1},
                  {'test3_2 -- Basic Partitioning From Cells', errs2_2}], test_rec);

// TEST 4 -- Multiply Operation
// Distort the A[1] matrix, so that its row-size is less than expected to simulate
// a matrix of the correct size with zeros across one edge.  All the following
// tests will use this matrix and should adjust its size accordingly.
amat1 := tm.Matrix(N1-1, M1, 1.0, 1);
amat2 := tm.Matrix(M1, N1, 1.0, 2);
bmat1 := tm.Matrix(M1, N1, 1.0, 1);
bmat2 := tm.Matrix(N1, M1, 1.0, 2);
cmat1 := tm.Matrix(N1, N1, 1.0, 1);
cmat2 := tm.Matrix(M1, M1, 1.0, 2);
adims := md.FromCells(amat1 + amat2, 'A');
bdims := md.FromCells(bmat1 + bmat2, 'B');
cdims := md.FromCells(cmat1 + cmat2, 'C');
pdims4 := md.PartitionedFromDimsForOp(OpType.multiply, adims+bdims+cdims);
pdims4a := pdims4(m_label = 'A');
pdims4b := pdims4(m_label = 'B');
pdims4c := pdims4(m_label = 'C');
pdims4a1 := pdims4a(wi_id = 1)[1];
pdims4b1 := pdims4b(wi_id = 1)[1];
pdims4c1 := pdims4c(wi_id = 1)[1];
// Just test basic relationships for one work item to keep the test simple
errs4_1 := IF(pdims4a1.col_blocks != pdims4b1.row_blocks OR
             pdims4a1.row_blocks != pdims4c1.row_blocks OR
             pdims4b1.col_blocks != pdims4c1.col_blocks, 1, 0);
test4 := DATASET([{'test4 -- Partitioning for Multiply Op', errs4_1}], test_rec);

// TEST 5 -- Solve_Ax Operation
pdims5 := md.PartitionedFromDimsForOp(OpType.solve_Ax, adims+bdims);
pdims5a := pdims5(m_label = 'A');
pdims5b := pdims5(m_label = 'B');
pdims5a1 := pdims5a(wi_id = 1)[1];
pdims5b1 := pdims5b(wi_id = 1)[1];
errs5_1 := IF(pdims5a1.col_blocks != pdims5a1.row_blocks OR
             pdims5a1.row_blocks != pdims5b1.row_blocks, 1, 0);
test5 := DATASET([{'test5 -- Partitioning for Solve_Ax Op', errs5_1}], test_rec);

// TEST 6 -- Solve_xA Operation
pdims6 := md.PartitionedFromDimsForOp(OpType.solve_xA, adims+bdims);
pdims6a := pdims6(m_label = 'A');
pdims6b := pdims6(m_label = 'B');
pdims6a1 := pdims6a(wi_id = 1)[1];
pdims6b1 := pdims6b(wi_id = 1)[1];
errs6_1 := IF(pdims6a1.col_blocks != pdims6a1.row_blocks OR
             pdims6a1.row_blocks != pdims6b1.col_blocks, 1, 0);
test6 := DATASET([{'test6 -- Partitioning for Solve_aX Op', errs6_1}], test_rec);

// TEST 7 -- Symmetric Operation
pdims7 := md.PartitionedFromDimsForOp(OpType.square, adims);
pdims7a := pdims6(m_label = 'A');
pdims7a1 := pdims6a(wi_id = 1)[1];
errs7_1 := IF(pdims6a1.col_blocks != pdims7a1.row_blocks OR
             pdims7a1.m_rows != pdims7a1.m_cols, 1, 0);
test7 := DATASET([{'test7 -- Partitioning for Symmetric Op', errs7_1}], test_rec);

// TEST 8 -- Parallel Operation
pdims8 := md.PartitionedFromDimsForOp(OpType.parallel, adims+bdims);
pdims8a := pdims8(m_label = 'A');
pdims8b := pdims8(m_label = 'B');
pdims8a1 := pdims8a(wi_id = 1)[1];
pdims8b1 := pdims8b(wi_id = 1)[1];
errs8_1 := IF(pdims8a1.col_blocks != pdims8b1.col_blocks OR
             pdims8a1.row_blocks != pdims8b1.row_blocks OR
             pdims8a1.m_rows != pdims8b1.m_rows OR
             pdims8a1.m_cols != pdims8b1.m_cols, 1, 0);
test8 := DATASET([{'test8 -- Partitioning for Parallel Op', errs8_1}], test_rec);


EXPORT MatDims := WHEN(test1 + test2 + test3 + test4 + test5 + test6 + test7 + test8, override);

