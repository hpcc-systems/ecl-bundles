/*##############################################################################
## HPCC SYSTEMS software Copyright (C) 2016 HPCC Systems®.  All rights reserved.
############################################################################## */

IMPORT $ as PBblas;
IMPORT PBblas.internal as int;
IMPORT int.MatDims;
IMPORT PBblas.Types;
IMPORT int.Types as iTypes;
IMPORT PBblas.Constants;

//Alias entries for convenience
Layout_Cell := Types.Layout_Cell;
Layout_Dims := iTypes.Layout_Dims;
value_t := Types.value_t;
dimension_t := PBblas.Types.dimension_t;
/**
  * Convert a vector into a diagonal matrix.  
  * The typical notation is D = diag(V).
  * The input X must be a 1 x N column vector or an N x 1 row vector.
  * The resulting matrix, in either case will be N x N, with zero everywhere
  * except the diagonal.
  *
  * @param X  A row or column vector (i.e. N x 1 or 1 x N) in Layout_Cell format
  * @return   An N x N matrix in Layout_Cell format
  * @see      PBblas/Types.Layout_cell
  */
EXPORT DATASET(Layout_Cell)
       Vector2Diag(DATASET(Layout_Cell) X):= FUNCTION

  rawdims := MatDims.FromCells(X);
  xdims := ASSERT(rawdims, m_rows = 1 OR m_cols = 1, PBblas.Constants.Dimension_Incompat, FAIL);
  
  Layout_Cell make_diag(Layout_Cell l, Layout_Dims r) := TRANSFORM
    is_row_vector := r.m_cols = 1;
    rc := IF(is_row_vector, l.x, l.y);
    SELF.x := rc;
    SELF.y := rc;
    SELF   := l;
  END;

  out_mat := JOIN(X, xdims, LEFT.wi_id = RIGHT.wi_id, make_diag(LEFT, RIGHT), LOOKUP);
  return out_mat;
END;
