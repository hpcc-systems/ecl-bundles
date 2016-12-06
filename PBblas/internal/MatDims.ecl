/*##############################################################################
## HPCC SYSTEMS software Copyright (C) 2016 HPCC Systems®.  All rights reserved.
############################################################################## */
IMPORT $.^ as PBblas;
IMPORT $ as int;
IMPORT PBblas.Types;
IMPORT int.Types as iTypes;
dimension_t := Types.dimension_t;
work_item_t := Types.work_item_t;
Layout_Cell := Types.Layout_Cell;
Layout_Dims := iTypes.Layout_Dims;
OpType      := iTypes.OpType;
m_label_t   := iTypes.m_label_t;
/**
  * Module to calculate matrix dimensions and matrix partition dimensions from
  * matrix cells.
  *
  */
EXPORT MatDims := MODULE
  /**
    * Get basic matrix dimensions (m_rows, m_cols) from a dataset of cells (Layout_Cell).
    * Multiple matrices can be included in the dataset separated by wi_id.  One record of 
    * Layout_Dims will be produced for each matrix in the input set. 
    * 
    * @param cells   dataset of Layout_Cell containing the matrixes to be dimensioned
    * @param m_label a single text label to be attached to the dimensions so that
    *                this set of dimensions can be distinguished from another set
    *                used by the same operation (e.g. 'A', 'B', or 'C')
    * @return        DATASET(Layout_Dims), one record per work item
    * @see Std/PBblas/Types.Layout_Cell
    * @see Std/PBblas/Types.Layout_Dims
    */
  EXPORT FromCells(DATASET(Layout_Cell) cells, m_label_t m_label='') := FUNCTION
    dims := RECORD
      m_label_t m_label := m_label;
      work_item_t wi_id := cells.wi_id;
      dimension_t m_rows := MAX(GROUP, cells.x);
      dimension_t m_cols := MAX(GROUP, cells.y);
    END;
    result1 := TABLE(cells, dims, wi_id, FEW, UNSORTED);
    DATASET(Layout_Dims) result2 := PROJECT(result1, Layout_Dims);
    return result2;
  END;
  /**
    * Determine optimal partitioning scheme for one or more matrixes based on the dimensions
    * provided.
    * 
    * @param dims            DATASET(Layout_Dims), typically output from FromCells above
    * @return                DATASET(Layout_Dims), with partition info filled in
    * @see Std/PBblas/Types.Layout_Dims
    */
  EXPORT PartitionedFromDims(DATASET(Layout_Dims) dims) := FUNCTION
    Layout_Dims do_partition(Layout_Dims lr) := TRANSFORM
      bd := int.BlockDimensions(lr.m_rows, lr.m_cols);
      SELF.row_blocks := bd.PN;
      SELF.col_blocks := bd.PM;
      SELF.block_rows := bd.BlockRows;
      SELF.block_cols := bd.BlockCols;
      SELF := lr;
    END;
    DATASET(Layout_Dims) rslt := PROJECT(dims, do_partition(LEFT));
    return rslt;
  END;
  /**
    * Generate a partitioning scheme from a set of matrices in cell form.
    * Essentially a shortcut for FromCells followed by PartitionedFromDims
    * 
    * @param cells   DATASET(Layout_Cell) representing one or more matrixes
    * @param m_label a single text label to be attached to the dimensions so that
    *                this set of dimensions can be distinguished from another set
    *                used by the same operation (e.g. 'A', 'B', or 'C')
    * @return        DATASET(Layout_Dims) with partition info filled in
    * @see Std/PBblas/Types.Layout_Dims
    * @see Std/PBblas/Types.Layout_Cell
    * @see FromCells
    * @see PartitionedFromDims
    */
  EXPORT PartitionedFromCells(DATASET(Layout_Cell) cells, m_label_t m_label='') := FUNCTION
    dims := FromCells(cells, m_label);
    DATASET(Layout_Dims) p_dims := PartitionedFromDims(dims);
    return p_dims;
  END;
  /**
    * Determines an optimal partitioning scheme for a set of matrixes involved in
    * a given operation.  This handles interlocking dimensions such as those involved
    * in a multiplication operation.  Note that calling this function with OpType.single
    * is equivalent to calling PartitionedFromDims above.
    * The input dimensions include dimensions from different work-items (separated by
    * wi_id) as well as dimensions from separate matrixes (e.g. A, B, and C/result)
    * within a work-item (separated by m_label).
    * Each operation-type may have a different expected set of m_labels and will perform
    * its interlock calculations accordingly.
    * 
    * @param op              The operation requiring partitioning.  See Types.OpType
    * @param dims            DATASET(Layout_Dims) typically returned by FromCells above
    * @return                DATASET(Layout_Dims) with patition info filled in.
    *                        This will contain one entry per work item, per
    *                        matrix label.
    * @see Std/PBblas/Types.Layout_Dims
    * @see Std/PBblas/Types.OpType
    * @see FromCells
    * @see PartitionedFromDims
    */
  EXPORT PartitionedFromDimsForOp(OpType op, DATASET(Layout_Dims) dims) := FUNCTION
    // A record of 3 interlocked matrix dimensions used for e.g. multiply
    dims3 := RECORD
      dimension_t N;
  	  dimension_t M;
  	  dimension_t P;
      dimension_t PN;
      dimension_t PM;
  	  dimension_t PP;
      Layout_Dims A;
      Layout_Dims B;
      Layout_Dims C;
    END;
    // A record of 2 interlocked matrix dimensions used for e.g. solve
    dims2 := RECORD
      dimension_t N;
      dimension_t M;
      dimension_t PN;
      dimension_t PM;
      Layout_Dims A;
      Layout_Dims B;
    END;
    // Function to perform partitioning for a single matrix (no interlocking)
    do_single := FUNCTION
      return PartitionedFromDims(dims);
    END;
    // Function to calculate partitioning for a multiplication operation with three
    // interlocked matrixes, 'A', 'B', and 'C'.
    // - A's rows must equal C's rows
    // - A's columns must equal B's rows
    // - B's columns must equal C's columns
    // Note that Layout_Cell based matrixes do not have an explicit size.  There
    // might be zeros in the last row or column.
    // Therefore, if these dimensions do not match on input, they will be forced
    // to match on output, so no errors will result from input mismatch.
    do_multiply := FUNCTION
      // Gathers A, B, and C matrixes into a single record, performs the interlocked
      // matrix partitioning calculations, and return a combined record with all
      // of the calculation results.
      dims3 do_work_item(Layout_Dims parent, DATASET(Layout_Dims) children) := TRANSFORM
    	  emptyC  := DATASET([{'C', parent.wi_id, 0, 0}], Layout_Dims)[1];
    	  Adims   := children[1];
    	  Bdims   := children[2];
    	  Cdims   := IF(COUNT(children) > 2, children[3], emptyC);
    	  N       := MAX([Adims.m_rows, Cdims.m_rows]);
    	  M       := MAX([Adims.m_cols, Bdims.m_rows]);
    	  P       := MAX([Bdims.m_cols, Cdims.m_cols]);
    	  bd      := int.BlockDimensionsMultiply(N, M, P);
    	  PN      := bd.PN;
    	  PM      := bd.PM;
    	  PP      := bd.PP;
    	  SELF.A  := Adims;
    	  SELF.B  := Bdims;
    	  SELF.C  := Cdims;
    	  SELF.N  := N;
    	  SELF.M  := M;
    	  SELF.P  := P;
    	  SELF.PN := PN;
    	  SELF.PM := PM;
    	  SELF.PP := PP;
      END;
      // Transforms a set of 3 interlocked partitioned dimensions to individual Layout_Dims
      // records
      Layout_Dims normalize_work_item(UNSIGNED c, dims3 wi) := TRANSFORM
        SELF.m_rows     := IF(c != 2, wi.N, wi.M);
        SELF.m_cols     := IF(c = 1, wi.M, wi.P);
        SELF.row_blocks := IF(c=1 OR c=3, wi.PN, wi.PM);
        SELF.col_blocks := IF(c=1, wi.PM, wi.PP);
        SELF.block_rows := ROUNDUP(IF(c=1 OR c=3, wi.N / wi.PN, wi.M / wi.PM));
        SELF.block_cols := ROUNDUP(IF(c=1, wi.M / wi.PM, wi.P / wi.PP));
        SELF.m_label    := CHOOSE(c, 'A', 'B', 'C');
        SELF            := IF(c=1, wi.A, IF(c=2, wi.B, wi.C));
        //SELF            := CHOOSE(c, wi.A, wi.B, wi.C);
      END;
      // Distribute to nodes based on wi_id 
      d1 := DISTRIBUTE(dims, wi_id);
      d2 := SORT(d1, wi_id, m_label, LOCAL);
      // Group dims with the same wi_id
      d3 := GROUP(d2, wi_id, LOCAL);
      // Merge A, B, and C dimensions into a single record for each wi_id
      // and compute partitioning of all 3 interlocked matrixes
      wi_dims := ROLLUP(d3, GROUP, do_work_item(LEFT, ROWS(LEFT)));
      // Separate the 3 interlocked dimensions so that we can return them
      // as individual Layout_Dims records, separated (once again) by m_label
      d4 := NORMALIZE(wi_dims, 3, normalize_Work_item(COUNTER, LEFT));
      return d4;
    END;
    // Function to calculate partitioning for a solve operation with two 
    // interlocked matrixes, 'A', and 'B'.
    // If op = OpType.solve_Ax:
    // - A's rows must equal A's columns (A is square)
    // - A's columns must equal B's rows
    // If op = OpType.solve_xA:
    // - A's rows must equal A's columns (A is square)
    // - A's rows must equal B's columns
    // Note that if these dimensions do not match on input, they will be forced
    // to match on output, so no errors will result from input mismatch.
    do_solve := FUNCTION
      // Gathers A and B matrixes into a single record, performs the interlocked
      // matrix partitioning calculations, and return a combined record with all
      // of the calculation results.
      dims2 do_work_item(Layout_Dims parent, DATASET(Layout_Dims) children) := TRANSFORM
        emptyC := DATASET([{'C', parent.wi_id, 0, 0}], Layout_Dims)[1];
        Adims := children[1];
        Bdims := children[2];
        // Normalize N and M so that N is always A's size, and M is the remaining side of B
        N_Ax := MAX([Adims.m_rows, Adims.m_cols, Bdims.m_rows]);
        N_xA := MAX([Adims.m_rows, Adims.m_cols, Bdims.m_cols]);
        N := IF(op = OpType.solve_Ax, N_Ax, N_xA);
        M := IF(op = OpType.solve_Ax, Bdims.m_cols, Bdims.m_rows);
        // Find the block dimensions for A (always square)
        bd := int.BlockDimensionsSolve(N, M);
        PN := bd.PN;
        PM := bd.PM;
        SELF.A := Adims;
        SELF.B := Bdims;
        SELF.N := N;
        SELF.M := M;
        SELF.PN := PN;
        SELF.PM := PM;
      END;
      // Transforms a set of 2 interlocked partitioned dimensions to individual Layout_Dims
      // records
      Layout_Dims normalize_work_item(UNSIGNED c, dims2 wi) := TRANSFORM
        b_rows := IF(op = OpType.solve_Ax, wi.N, wi.M);
        b_cols := IF(op = OpType.solve_Ax, wi.M, wi.N);
        SELF.m_rows := IF(c = 1, wi.N, b_rows);
        SELF.m_cols := IF(c = 1, wi.N, b_cols);
        b_row_blocks := IF(op = OpType.solve_Ax, wi.PN, wi.PM);
        b_col_blocks := IF(op = OpType.solve_Ax, wi.PM, wi.PN);
        SELF.row_blocks := IF(c=1, wi.PN, b_row_blocks);
        SELF.col_blocks := IF(c=1, wi.PN, b_col_blocks);
        SELF.block_rows := ROUNDUP(IF(c=1, wi.N / wi.PN, b_rows / b_row_blocks));
        SELF.block_cols := ROUNDUP(IF(c=1, wi.N / wi.PN, b_cols / b_col_blocks));
        SELF.m_label := IF(c=1, 'A', 'B');
        SELF := IF(c=1, wi.A, wi.B);
      END;
      // Distribute to nodes based on wi_id 
      d1 := DISTRIBUTE(dims, wi_id);
      d2 := SORT(d1, wi_id, m_label, LOCAL);
      // Group dims with the same wi_id
      d3 := GROUP(d2, wi_id, LOCAL);
      // Merge A and B dimensions into a single record for each wi_id
      // and compute partitioning of both interlocked matrixes
      wi_dims := ROLLUP(d3, GROUP, do_work_item(LEFT, ROWS(LEFT)));
      // Separate the 2 interlocked dimensions so that we can return them
      // as individual Layout_Dims records, separated (once again) by m_label
      d4 := NORMALIZE(wi_dims, 2, normalize_Work_item(COUNTER, LEFT));
      return d4;
    END;
    // Function to calculate dimensions for a square matrix 
    // where rows = columns
    Layout_Dims do_square := FUNCTION
      Layout_Dims make_symmetric(Layout_Dims dims) := TRANSFORM
        m_rows := dims.m_rows;
        m_cols := dims.m_cols;
        new_dim := MAX([m_rows, m_cols]);
        // Use the biggest of rows or columns as the dim for both
        SELF.m_rows := new_dim;
        SELF.m_cols := new_dim;
        SELF        := dims;
      END;
      new_dims := PROJECT(dims, make_symmetric(LEFT));
      result := PartitionedFromDims(new_dims);
      return result;
    END;
    // Function to calculate dimensions of parallel matrixes, i.e. same
    // shape for each m_label for a work item 
    Layout_Dims do_parallel := FUNCTION
      Layout_Dims get_max(Layout_Dims dims, DATASET(Layout_Dims) all_dims) := TRANSFORM
        SELF.wi_id := dims.wi_id;
        SELF.m_rows := MAX(all_dims, all_dims.m_rows);
        SELF.m_cols := MAX(all_dims, all_dims.m_cols);
        bd := int.BlockDimensions(SELF.m_rows, SELF.m_cols);
        SELF.row_blocks := bd.PN;
        SELF.col_blocks := bd.PM;
        SELF.block_rows := bd.BlockRows;
        SELF.block_cols := bd.BlockCols;
        SELF := dims;
      END;
      dims_dist := DISTRIBUTE(dims, wi_id);
      dims_sorted := SORT(dims_dist, wi_id, LOCAL);
      dims_grouped := GROUP(dims_sorted, wi_id, LOCAL);
      dims_max := ROLLUP(dims_grouped, GROUP, get_max(LEFT, ROWS(LEFT)));
      Layout_Dims fixup_dims(Layout_Dims d, Layout_Dims m) := TRANSFORM
        // Use all dimensions from the max, but keep the m_label.
        // Wi_id is the same for both.
        SELF.m_label := d.m_label;
        SELF := m;
      END;
      result := JOIN(dims_sorted, dims_max, LEFT.wi_id = RIGHT.wi_id, fixup_dims(LEFT, RIGHT), LOOKUP);
      return result;
    END;

    // Call the appropriate function based on the operation
    DATASET(Layout_Dims) results := IF(op = OpType.multiply, do_multiply,
               IF(op = OpType.solve_Ax OR op = OpType.solve_xA, do_solve, 
               IF(op = OpType.square, do_square, 
               IF(op = OpType.parallel, do_parallel, do_single))));
    return results;
  END;
  /**
    * Transpose rows and columns for a set of matrix dimensions.
    * Can be used for single matrix dimensions or partitioned matrixes.
    * Returns one record for each input record.  Many matrixes can
    * be included in one call.
    *
    * @param dims_in   The dimensions to be transposed in Layout_Dims format
    * @return          DATASET(Layout_Dims), the input dimensions transposed
    *
    */
  EXPORT TransposeDims(DATASET(Layout_Dims) dims_in) := FUNCTION
    // Swaps rows and columns
    Layout_Dims do_trans(Layout_Dims dims) := TRANSFORM
      SELF.m_rows := dims.m_cols;
      SELF.m_cols := dims.m_rows;
      SELF.block_rows := dims.block_cols;
      SELF.block_cols := dims.block_rows;
      SELF.row_blocks := dims.col_blocks;
      SELF.col_blocks := dims.row_blocks;
      SELF := dims;
    END;
    DATASET(Layout_Dims) result := PROJECT(dims_in, do_trans(LEFT));
    return result;
  END;
END;
