/*##############################################################################
## HPCC SYSTEMS software Copyright (C) 2016 HPCC Systems®.  All rights reserved.
############################################################################## */

IMPORT $ as PBblas;
IMPORT PBblas.Types;
IMPORT PBblas.internal as int;
IMPORT int.Types as iTypes;
IMPORT int.MatDims;
IMPORT int.Converted;
IMPORT Std.BLAS;
IMPORT std.system.Thorlib;

//Alias entries for convenience
Layout_Cell := Types.Layout_Cell;
Layout_Part := iTypes.Layout_Part;
value_t := Types.value_t;
OpType := iTypes.OpType;
empty_c := DATASET([], Layout_Cell);
/**
  *  Transpose a matrix and sum into base matrix
  *   result <== alpha * A**t  + beta * C, A is n by m, C is m by n
  *   A**T (A Transpose)  and C must have same shape
  *  @param alpha  Scalar multiplier for the A**T matrix
  *  @param A      A matrix in DATASET(Layout_Cell) form
  *  @param beta   Scalar multiplier for the C matrix
  *  @param C      C matrix in DATASET(Layout_Call) form
  *  @return	   Matrix in DATASET(Layout_Cell) form alpha * A**T + beta * C
  *  @see		   PBblas/Types.layout_cell
  */
  EXPORT DATASET(Layout_Cell)
      tran(value_t alpha, DATASET(Layout_Cell) A, value_t beta=0, 
                   DATASET(Layout_Cell) C=empty_c) := FUNCTION
  Layout_Cell add(Layout_Cell l, Layout_Cell r) := TRANSFORM
    SELF.v := alpha*l.v + beta*r.v;
    SELF := l;
  END;
  Layout_Cell trans(Layout_Cell lr) := TRANSFORM
    SELF.x := lr.y;
    SELF.y := lr.x;
    SELF   := lr;
  END;
  have_c := beta != 0 AND EXISTS(C);
  A_trans := PROJECT(A, trans(LEFT));
  A_dist := SORT(DISTRIBUTE(A_trans, HASH32(wi_id, x, y)), wi_id, x, y, LOCAL);
  C_dist := SORT(DISTRIBUTE(C, HASH32(wi_id, x, y)), wi_id, x, y, LOCAL);

  result := IF(have_c, 
             JOIN(A_dist, C_dist, LEFT.wi_id = LEFT.wi_id
                  AND LEFT.x = RIGHT.x 
                  AND LEFT.y = RIGHT.y, add(LEFT, RIGHT), LEFT OUTER, LOCAL), 
             A_dist);
  RETURN result;
END;