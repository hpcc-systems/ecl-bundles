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
Layout_Cell := Types.Layout_Cell;
Layout_Part := iTypes.Layout_Part;
Layout_Norm := Types.Layout_Norm;
value_t := Types.value_t;
work_item_t := Types.work_item_t;
OpType := iTypes.OpType;

/**
  * Absolute sum -- the "Entrywise" 1-norm
  *
  * Compute SUM(ABS(X))
  *
  * @param X    Matrix or set of matrices in Layout_Cell format
  * @return     DATASET(Layout_Norm) with one record per work item
  * @see        PBblas/Types.Layout_Cell
  */
EXPORT DATASET(Layout_Norm) asum(DATASET(Layout_Cell) X) := FUNCTION
  // Sum the absolute values for each work-item
  table_rec := RECORD
    X.wi_id;
    v     := SUM(GROUP, ABS(X.v));
  END;
  reslt_table := TABLE(X, table_rec, wi_id, FEW, UNSORTED);
  reslt := PROJECT(reslt_table, Layout_Norm);
  RETURN reslt;
END;
