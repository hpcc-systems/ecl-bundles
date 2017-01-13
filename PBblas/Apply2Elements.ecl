/*##############################################################################
## HPCC SYSTEMS software Copyright (C) 2016 HPCC Systems®.  All rights reserved.
############################################################################## */

IMPORT $ as PBblas;
IMPORT PBblas.Types;
IMPORT Std.BLAS;
//Alias entries for convenience
Layout_Cell := Types.Layout_Cell;
value_t := Types.value_t;
IElementFunc := PBblas.IElementFunc;
dim_t := PBblas.Types.dimension_t;

/**
  * Apply a function to each element of the matrix
  *
  * Use PBblas.IElementFunc as the prototype function.
  * Input and ouput may be a single matrix, or myriad matrixes with
  * different work item ids.
  * 
  * @param X       A matrix (or multiple matrices) in Layout_Cell form
  * @param f       A function based on the IElementFunc prototype
  * @return        A matrix (or multiple matrices) in Layout_Cell form
  * @see           PBblas/IElementFunc
  * @see           PBblas/Types.Layout_Cell
  */
EXPORT DATASET(Layout_Cell) Apply2Elements(DATASET(Layout_Cell) X, 
                                           IElementFunc f) := FUNCTION
  Layout_Cell apply_func(Layout_Cell lr) := TRANSFORM
    new_v := f(lr.v, lr.x, lr.y);
    SELF.v := new_v;
    SELF   := lr;
  END;
  DATASET(Layout_Cell) rslt := PROJECT(X, apply_func(LEFT));
  return rslt;
END;
