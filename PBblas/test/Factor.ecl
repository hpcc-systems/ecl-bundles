// Test for the factorization definitions.  Cholesky and LU.
IMPORT $.^ as PBblas;
IMPORT PBblas.internal as int;
IMPORT int.Types as iTypes;
IMPORT $ as Tests;
IMPORT PBblas.Types;
Layout_Cell := Types.Layout_Cell;
matrix_t := iTypes.matrix_t;
Triangle := Types.Triangle;
Upper  := Triangle.Upper;
Lower  := Triangle.Lower;
Diagonal := Types.Diagonal;
UnitTri := Types.Diagonal.UnitTri;
NotUnitTri := Types.Diagonal.NotUnitTri;

LU_Test := Tests.getrf;
CH_Test := Tests.potrf;
rslt := LU_Test + CH_Test;
EXPORT Factor := rslt;
