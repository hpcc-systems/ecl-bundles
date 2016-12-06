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

alpha := -2.1; // Arbitrary
N1 := 100;
M1 := 200;
Xmat1 := tm.Matrix(N1, M1, 1.0, 1);
Xmat2 := tm.Matrix(M1, N1, 1.0, 2);

// Test myriad case with two different matrixes to scale
newmat := PBblas.scal(alpha, Xmat1+Xmat2);
new1 := newmat(wi_id = 1);
new2 := newmat(wi_id = 2);

// TEST 1 -- Validate matrix dimensions
dims_1 := MatDims.FromCells(new1)[1];
dims_2 := MatDims.FromCells(new2)[1];

// Result should be same shape as original
err1_1 := IF(dims_1.m_rows != N1 OR dims_1.m_cols != M1, 1, 0);
err1_2 := IF(dims_2.m_rows != M1 OR dims_2.m_cols != N1, 1, 0);
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
tp1_x := 37;
tp1_y := 1;
tp2_x := 100;
tp2_y := 50;
Xval1_1 := Xmat1(x = tp1_x AND y = tp1_y)[1].v * alpha;
Xval2_1 := Xmat2(x = tp1_x AND y = tp1_y)[1].v * alpha;
Xval1_2 := Xmat1(x = tp2_x AND y = tp2_y)[1].v * alpha;
Xval2_2 := Xmat2(x = tp2_x AND y = tp2_y)[1].v * alpha;

Rval1_1 := new1(x = tp1_x AND y = tp1_y)[1].v;
Rval2_1 := new2(x = tp1_x AND y = tp1_y)[1].v;
Rval1_2 := new1(x = tp2_x AND y = tp2_y)[1].v;
Rval2_2 := new2(x = tp2_x AND y = tp2_y)[1].v;

err2_1_1 := IF(Xval1_1 != Rval1_1, 1, 0);
err2_2_1 := IF(Xval2_1 != Rval2_1, 1, 0);
err2_1_2 := IF(Xval1_2 != Rval1_2, 1, 0);
err2_2_2 := IF(Xval2_2 != Rval2_2, 1, 0);

test2 := DATASET([  {'Test2_1 -- Verify Values', err2_1_1},
					{'Test2_2 -- Verify Values', err2_2_1},
					{'Test2_3 -- Verify Values', err2_1_2, 'Xval1_2 = ' + Xval1_2 + ', Rval1_2 = ' + Rval1_2},
					{'Test2_4 -- Verify Values', err2_2_2}
					], test_rec);

result := test1 + test2;
/**
  *  Test for PBblas.PB_dscal
  */
EXPORT scal := result;
