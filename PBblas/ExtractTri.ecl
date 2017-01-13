/*##############################################################################
## HPCC SYSTEMS software Copyright (C) 2016 HPCC Systems®.  All rights reserved.
############################################################################## */
IMPORT $ as PBblas;
IMPORT Std.BLAS;
IMPORT PBblas.Types;
IMPORT PBblas.internal as int;
IMPORT int.Types as iTypes;
IMPORT int.MatDims;
IMPORT int.Converted;
Layout_Part := iTypes.Layout_Part;
Layout_Cell := Types.Layout_Cell;
Triangle := Types.Triangle;
Upper:= Types.Triangle.Upper;
Lower:= Types.Triangle.Lower;
Diagonal := Types.Diagonal;

/**
  *  Extract the upper or lower triangle from the composite output from 
  *  getrf (LU Factorization).
  *
  *  @param tri    Triangle type:  Upper or Lower (see Types.Triangle)
  *  @param dt     Diagonal type:  Unit or non unit (see Types.Diagonal)
  *  @param A      Matrix of cells. See Types.Layout_Cell
  *  @return       Matrix of cells in Layout_Cell format representing
  *                a triangular matrix (upper or lower)
  *  @see          Std.PBblas.Types
  */
EXPORT DATASET(Layout_Cell) ExtractTri(Triangle tri, Diagonal dt,
                      DATASET(Layout_Cell) A) := FUNCTION
  // If Diagonal type is UnitTri, then all of the diagonals should be set to 1.0.                    
  Layout_Cell fix_diagonal(Layout_Cell lr) := TRANSFORM
    new_val := IF(lr.x = lr.y, 1.0, lr.v);
    SELF.v  := new_val;
    SELF    := lr;
  END;
  // Upper triangular
  upperCells := A(x <= y);
  // Lower triangular
  lowerCells := A(x >= y);
  tri_cells := IF(tri = Lower, lowerCells, upperCells);
  // If dt is UnitTriangle, fixup the diagonal entries, else return what we have.
  rslt := IF(dt = Diagonal.NotUnitTri, tri_cells, PROJECT(tri_cells, fix_diagonal(LEFT)));
  RETURN rslt;
END;
