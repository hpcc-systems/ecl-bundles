/*##############################################################################
## HPCC SYSTEMS software Copyright (C) 2016 HPCC Systems®.  All rights reserved.
############################################################################## */

// Test the performance of the triangular solver
IMPORT $.^ as PBblas;
IMPORT PBblas.internal as int;
IMPORT PBblas.MatUtils;
IMPORT PBblas.Types;
IMPORT int.Types as iTypes;
IMPORT PBblas.test as Tests;
IMPORT Tests.MakeTestMatrix as tm;

matrix_t := iTypes.matrix_t;
Triangle := Types.Triangle;
Diagonal := Types.Diagonal;
Upper  := Triangle.Upper;
Lower  := Triangle.Lower;
Layout_Part := iTypes.Layout_Part;
Side := Types.Side;


// TEST 1 -- Basic functionality with single partition (small matrix)


N1 := 10000;
M1 := 1000000;

A1 := tm.RandomPersist(N1, N1, 1.0, 1, 'A1P');
             
X1 := tm.RandomPersist(N1, M1, 1.0, 1, 'X1P');

B1 := PBblas.gemm(FALSE, FALSE, 1.0,
             A1, X1) : PERSIST('B1P_' + N1 + '_' + M1);

A1_factored := PBblas.getrf(A1) : PERSIST('A1PF_' + N1 + '_' + M1);

S1 := PBblas.trsm(Side.Ax, Lower, FALSE, Diagonal.UnitTri,
                      1.0, A1_factored, B1);

result := COUNT(S1);

EXPORT SolvePerf := result;
