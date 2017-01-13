/*##############################################################################
## HPCC SYSTEMS software Copyright (C) 2016 HPCC Systems®.  All rights reserved.
############################################################################## */
IMPORT $.^ as PBblas;
IMPORT PBblas.Types;
IMPORT $ as Tests;
IMPORT Tests.MakeTestMatrix as tm;

value_t := Types.value_t;
dimension_t := Types.dimension_t;

value_t squareIt(value_t v, dimension_t r, dimension_t c) := v * v;

N1 := 100;
M1 := 200;
X := tm.Matrix(N1, M1, 1.0, 1);
rslt1 := PBblas.Apply2Elements(X, squareIt);
rslt2 := PBblas.HadamardProduct(X, X);
rslt  := Tests.DiffReport.compare_cells('TEST 1', rslt1, rslt2);
EXPORT Apply2Elements := rslt;