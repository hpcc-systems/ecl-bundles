/*##############################################################################
## HPCC SYSTEMS software Copyright (C) 2016 HPCC Systems®.  All rights reserved.
############################################################################## */

IMPORT $ as PBBlas;
IMPORT PBBlas.Types;
Layout_Cell := Types.Layout_Cell;
value_t := Types.value_t;
/**
  *  Implements  alpha*X  + Y
  *   X and Y must have same shape
  *
  *  @param alpha  Scalar multiplier for the X matrix
  *  @param X      X matrix in DATASET(Layout_Cell) form
  *  @param Y      Y matrix in DATASET(Layout_Call) form
  *  @return	   Matrix in DATASET(Layout_Cell) form
  *  @see		   PBblas/Types.layout_cell
  */
EXPORT DATASET(Layout_Cell) axpy(value_t alpha, DATASET(Layout_Cell) X, DATASET(Layout_Cell) Y) := FUNCTION
  // This is a cell-by-cell operation, so no need to partition.
  Layout_Cell add(Layout_Cell l, Layout_Cell r) := TRANSFORM
    SELF.v := alpha*l.v + r.v;
    SELF := l;
  END;
  X_dist := SORT(DISTRIBUTE(X, HASH32(wi_id, x, y)), wi_id, x, y, LOCAL);
  Y_dist := SORT(DISTRIBUTE(Y, HASH32(wi_id, x, y)), wi_id, x, y, LOCAL);
  rs := JOIN(X_dist, Y_dist, LEFT.wi_id = RIGHT.wi_id AND
  						LEFT.x = RIGHT.x AND
  						LEFT.y = RIGHT.y,
             	add(LEFT,RIGHT), FULL OUTER, LOCAL);
  RETURN rs;
END;