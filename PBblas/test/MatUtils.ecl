/*##############################################################################
## HPCC SYSTEMS software Copyright (C) 2016 HPCC Systems®.  All rights reserved.
############################################################################## */

test_rec := RECORD
  STRING test;
  UNSIGNED errors;
  STRING details := '';
END;


IMPORT $.^ as PBblas;
IMPORT PBblas.MatUtils as mu;
IMPORT PBblas.internal as int;
IMPORT int.MatDims;
IMPORT $ as Tests;
IMPORT Tests.MakeTestMatrix as tm;

// TEST 1 -- Get Work Items
N := 1000;
M := 10;
mat1 := tm.Matrix(N, M, 1.0, 1);
mat2 := tm.Matrix(M, N, 1.0, 2);
wi_ids := mu.GetWorkItems(mat1 + mat2);
err1_1 := IF(COUNT(wi_ids) != 2, 1, 0);
err1_2 := IF(NOT EXISTS(wi_ids(wi_id = 1)), 1, 0);
err1_3 := IF(NOT EXISTS(wi_ids(wi_id = 2)), 1, 0);
test1 := DATASET([{'Test1_1 -- Get Work Items', err1_1},
					{'Test1_2 -- Get Work Items', err1_2},
					{'Test1_3 -- Get Work Items', err1_3}
					], test_rec);
// TEST 2 -- Insert Columns
colsToIns := 2;
insVal := 1.0;

// Insert one column with value 1.0
newM := mu.InsertCols(mat1 + mat2, colsToIns, insVal);
new2_1 := newM(wi_id = 1);
new2_2 := newM(wi_id = 2);
dims2_1 := MatDims.FromCells(new2_1);
dims2_2 := MatDims.FromCells(new2_2);
// For each, verify:
//           1) The number of coluns is orig + colsToInsert
//           2) The inserted value = insVal (spot check)
//           3) There are no extra cells
err2_1_1 := IF(dims2_1[1].m_cols != (M + colsToIns), 1, 0);
err2_1_2 := IF(new2_1(x=10 AND y=1)[1].v != insVal, 1, 0);
err2_1_3 := IF(COUNT(new2_1) != COUNT(mat1) + N * colsToIns, 1, 0);
err2_2_1 := IF(dims2_2[1].m_cols != (N + colsToIns), 1, 0);
err2_2_2 := IF(new2_2(x=10 AND y=1)[1].v != insVal, 1, 0);  
err2_2_3 := IF(COUNT(new2_2) != COUNT(mat2) + M * colsToIns, 1, 0);
test2    := DATASET([{'Test2_1_1 -- Insert Columns', err2_1_1},
					 {'Test2_1_2 -- Insert Columns', err2_1_2},
					 {'Test2_1_3 -- Insert Columns', err2_1_3},
					 {'Test2_2_1 -- Insert Columns', err2_2_1},
					 {'Test2_2_2 -- Insert Columns', err2_2_2},
					 {'Test2_2_3 -- Insert Columns', err2_2_3}
					 ], test_rec);

// TEST 3 -- Transpose
// Use the matrixes from TEST 1
trans := mu.Transpose(mat1 + mat2);
new3_1 := trans(wi_id = 1);
new3_2 := trans(wi_id = 2);
// Test the dimensions
dims3_1 := MatDims.FromCells(new3_1);
dims3_2 := MatDims.FromCells(new3_2);
err3_1 := IF(dims3_1.m_rows != M OR dims3_1.m_cols != N, 1, 0);
err3_2 := IF(dims3_2.m_rows != N OR dims3_2.m_cols != M, 1, 0);
// Sample a few points
tp1_x := 5;
tp1_y := 3;
tp2_x := 7;
tp2_y := 1;
Val3_1_1 := mat1(x = tp1_y AND y = tp1_x)[1].v;
R3_1_1 := new3_1(x = tp1_x AND y = tp1_y)[1].v;
err3_1_1 := IF(R3_1_1 != Val3_1_1, 1, 0);
Val3_2_1 := mat2(x = tp1_y AND y = tp1_x)[1].v;
R3_2_1 := new3_2(x = tp1_x AND y = tp1_y)[1].v;
err3_2_1 := IF(R3_2_1 != Val3_2_1, 1, 0);


Val3_1_2 := mat1(x = tp2_y AND y = tp2_x)[1].v;
R3_1_2 := new3_1(x = tp2_x AND y = tp2_y)[1].v;
err3_1_2 := IF(R3_1_2 != Val3_1_2, 1, 0);
Val3_2_2 := mat2(x = tp2_y AND y = tp2_x)[1].v;
R3_2_2 := new3_2(x = tp2_x AND  y = tp2_y)[1].v;
err3_2_2 := IF(R3_2_2 != Val3_2_2, 1, 0);
test3   := DATASET([{'Test3_1_1 -- Transpose', err3_1_1},
					{'Test3_2_1 -- Transpose', err3_2_1},
					{'Test3_1_2 -- Transpose', err3_1_2},
					{'Test3_2_2 -- Transpose', err3_2_2}
					], test_rec);

/**
  * Test for the various attributes of Std/PBblas/MatUtils.ecl
  */
EXPORT MatUtils := test1 + test2 + test3;