/*##############################################################################
## HPCC SYSTEMS software Copyright (C) 2016 HPCC Systems®.  All rights reserved.
############################################################################## */
IMPORT $.^ as PBblas;
IMPORT PBblas.Types;
IMPORT PBblas.internal as int;
IMPORT $ as Tests;
IMPORT Tests.MakeTestMatrix as tm;

Layout_Cell := Types.Layout_Cell;

epsilon := .00001; // Max FP error

max_partition_size := 1000;
override := #STORED('BlockDimensions_max_partition_size', max_partition_size);

// TEST 1 -- Verify the results vs manual computation
SET OF REAL8 X11_set := [-1, 3, -5.2,
				      .1, .8, -44,
				       0, 0, 21];

SET OF REAL8 X12_set := [11.4, 2,
						.37, -4.12,
						-8.8, 1.04,
						5.3, -3.14];
cmp1 := 75.1; // Manual computation
cmp2 := 36.17; // "
Layout_Cell set_wi(Layout_Cell c, UNSIGNED wi) := TRANSFORM
  SELF.wi_id := wi;
  SELF       := c;
END;
X11 := PROJECT(int.FromR8Set(X11_set, 3), set_wi(LEFT, 1));
X12 := PROJECT(int.FromR8Set(X12_set, 4), set_wi(LEFT, 2));
norms1 := PBblas.asum(X12 + X11);
norm11 := norms1(wi_id = 1)[1].v;
norm12 := norms1(wi_id = 2)[1].v;


reslt_rec := RECORD
  STRING test_name;
  UNSIGNED errors;
  STRING details := '';
END;

errors1 := IF((norm11 - cmp1)/norm11 > epsilon, 1, 0);
errors2 := IF((norm12 - cmp2)/norm12 > epsilon, 1, 0);

// TEST 2 -- Myriad test with multiple partitions
N1 := 500;
M1 := 623;
N2 := 811;
M2 := 393;
X21 := tm.Matrix(N1, M1, 1.0, 1);
X22 := tm.Matrix(N2, M2, .3, 2);
norms2 := PBblas.asum(X21+X22);
norm21 := norms2(wi_id = 1)[1].v;
norm22 := norms2(wi_id = 2)[1].v;

cmp21 := SUM(X21, ABS(v));
cmp22 := SUM(X22, ABS(v));

errors2a := IF((norm21 - cmp21)/norm21 > epsilon, 1, 0);
errors2b := IF((norm22 - cmp22)/norm22 > epsilon, 1, 0);

rslt := DATASET([{'TEST 1a', errors1, 'norm = ' + norm11 + ', cmp1 = 75.1'},
				 {'TEST 1b', errors2, 'norm = ' + norm12 + ', cmp2 = 36.17'},
				 {'TEST 2a', errors2a, 'norm = ' + norm21 + ', cmp = ' + cmp21},
				 {'TEST 2b', errors2b}], reslt_rec);

EXPORT asum := WHEN(rslt, override);
