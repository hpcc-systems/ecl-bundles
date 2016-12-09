/*##############################################################################
## HPCC SYSTEMS software Copyright (C) 2016 HPCC Systems®.  All rights reserved.
############################################################################## */

IMPORT $ as PBBlas;
IMPORT PBblas.internal as int;
IMPORT int.MatDims;
IMPORT PBblas.Types;
IMPORT int.Types as iTypes;
IMPORT int.Converted;
IMPORT Std.BLAS;
IMPORT Std.system.Thorlib;

//Alias entries for convenience
Layout_Cell := Types.Layout_Cell;
Layout_Part := iTypes.Layout_Part;
value_t := Types.value_t;
OpType := iTypes.OpType;

/**
  * Element-wise multiplication of X * Y.  
  * 
  * Supports the "myriad" style interface -- X and Y may contain 
  * multiple separate matrixes.  Each X will be multiplied by the
  * Y with the same work-item id.
  *
  * Note:  This performs element-wise multiplication. For dot-product
  * matrix multiplication, use PBblas.gemm.
  * 
  * @param X       A matrix (or multiple matrices) in Layout_Cell form
  * @param Y       A matrix (or multiple matrices) in Layout_Cell form
  * @return        A matrix (or multiple matrices) in Layout_Cell form
  * @see           PBblas/Types.Layout_Cell
  */
EXPORT DATASET(Layout_Cell)
      HadamardProduct(DATASET(Layout_Cell) X, DATASET(Layout_Cell) Y) := FUNCTION
  Layout_Cell mult(Layout_Cell l, Layout_Cell r) := TRANSFORM
    SELF.v := l.v * r.v;
    SELF := l;  // Arbitrary
  END;
  X_dist := SORT(DISTRIBUTE(X, HASH32(wi_id, x, y)), wi_id, x, y, LOCAL);
  Y_dist := SORT(DISTRIBUTE(Y, HASH32(wi_id, x, y)), wi_id, x, y, LOCAL);
  
  result := JOIN(X_dist, Y_dist, LEFT.wi_id = RIGHT.wi_id AND LEFT.x = RIGHT.x AND LEFT.y = RIGHT.y, mult(LEFT, RIGHT), LOCAL);
  RETURN result;
END;