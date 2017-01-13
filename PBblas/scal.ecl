/*##############################################################################
## HPCC SYSTEMS software Copyright (C) 2016 HPCC Systems®.  All rights reserved.
############################################################################## */

IMPORT $ as PBblas;
IMPORT PBblas.Types;

Layout_Cell := Types.Layout_Cell;
value_t := Types.value_t;

/**
  * Scale a matrix by a constant
  * Result is alpha * X
  * 
  * This supports a "myriad" style interface in that X may be a set
  * of independent matrices separated by different work-item ids.
  *
  * @param alpha   A scalar multiplier
  * @param X       The matrix(es) to be scaled in Layout_Cell format
  * @return		   Matrix in Layout_Cell form, of the same shape as X
  * @see		   PBblas/Types.Layout_Cell
  */
EXPORT DATASET(Layout_Cell) scal(value_t alpha, DATASET(Layout_Cell) X) := FUNCTION
  Layout_Cell scale(Layout_Cell lr) := TRANSFORM
    SELF.v := lr.v * alpha;
    SELF := lr;
  END;
  RETURN PROJECT(X, scale(LEFT));
END;