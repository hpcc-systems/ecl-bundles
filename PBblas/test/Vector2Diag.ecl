/*##############################################################################
## HPCC SYSTEMS software Copyright (C) 2016 HPCC Systems®.  All rights reserved.
############################################################################## */
IMPORT $ as Tests;
IMPORT $.^ as PBblas;
IMPORT PBblas.internal as int;
IMPORT int.MatDims;
IMPORT PBblas.Types;
IMPORT Tests.MakeTestMatrix as tm;
IMPORT Tests.DiffReport as dr;

Layout_Cell := Types.Layout_Cell;

test_rec := RECORD
  STRING test;
  UNSIGNED errors;
  STRING details := '';
END;

N1 := 1;
M1 := 1000;
Xmat1 := tm.Matrix(N1, M1, 1.0, 1);
Xmat2 := tm.Matrix(M1, N1, 1.0, 2);

// Test myriad case with a column vector and a row vector in the same test.
newmat := PBblas.Vector2Diag(Xmat1+Xmat2);
new1 := newmat(wi_id = 1);
new2 := newmat(wi_id = 2);

// TEST 1 -- Validate matrix dimensions
dims_1 := MatDims.FromCells(new1)[1];
dims_2 := MatDims.FromCells(new2)[1];

err1_1 := IF(dims_1.m_rows != M1 OR dims_1.m_cols != M1, 1, 0);
err1_2 := IF(dims_2.m_rows != M1 OR dims_2.m_cols != M1, 1, 0);
// Make sure that we have the same number of cells as we started out with
// (i.e. no extra non-zero cells)
err1_3 := IF(COUNT(new1) != COUNT(Xmat1), 1, 0);
err1_4 := IF(COUNT(new2) != COUNT(Xmat2), 1, 0);

test1 := DATASET([{'Test1_1 -- Verify Dimensions', err1_1},
					{'Test1_2 -- Verify Dimensions', err1_2},
					{'Test1_3 -- Verify Dimensions', err1_3},
					{'Test1_4 -- Verify Dimensions', err1_4}
					], test_rec);

// TEST 2 -- Validate Values
// Spot check a few values
tp1 := 1;
tp2 := 500;
tp3 := 1000;
Xval1_1 := Xmat1(y = tp1 AND x = 1)[1].v;
Xval2_1 := Xmat2(x = tp1 AND y = 1)[1].v;
Xval1_2 := Xmat1(y = tp2 AND x = 1)[1].v;
Xval2_2 := Xmat2(x = tp2 AND y = 1)[1].v;
Xval1_3 := Xmat1(y = tp3 AND x = 1)[1].v;
Xval2_3 := Xmat2(x = tp3 AND y = 1)[1].v;
Rval1_1 := new1(x = tp1 AND y = tp1)[1].v;
Rval2_1 := new2(x = tp1 AND y = tp1)[1].v;
Rval1_2 := new1(x = tp2 AND y = tp2)[1].v;
Rval2_2 := new2(x = tp2 AND y = tp2)[1].v;
Rval1_3 := new1(x = tp3 AND y = tp3)[1].v;
Rval2_3 := new2(x = tp3 AND y = tp3)[1].v;
err2_1_1 := IF(Xval1_1 != Rval1_1, 1, 0);
err2_2_1 := IF(Xval2_1 != Rval2_1, 1, 0);
err2_1_2 := IF(Xval1_2 != Rval1_2, 1, 0);
err2_2_2 := IF(Xval2_2 != Rval2_2, 1, 0);
err2_1_3 := IF(Xval1_3 != Rval1_3, 1, 0);
err2_2_3 := IF(Xval2_3 != Rval2_3, 1, 0);

test2 := DATASET([  {'Test2_1 -- Verify Values', err2_1_1},
					{'Test2_2 -- Verify Values', err2_2_1},
					{'Test2_3 -- Verify Values', err2_1_2, 'Xval1_2 = ' + Xval1_2 + ', Rval1_2 = ' + Rval1_2},
					{'Test2_4 -- Verify Values', err2_2_2},
					{'Test2_5 -- Verify Values', err2_1_3},
					{'Test2_6 -- Verify Values', err2_2_3}
					], test_rec);

result := test1 + test2;
/**
  *  Test for PBblas.Vector2Diag
  */
EXPORT Vector2Diag := result;
