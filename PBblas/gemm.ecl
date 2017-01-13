/*##############################################################################
## HPCC SYSTEMS software Copyright (C) 2016 HPCC Systems®.  All rights reserved.
############################################################################## */

IMPORT $ as PBblas;
IMPORT PBblas.Types;
IMPORT PBblas.internal as int;
IMPORT int.Types as iTypes;
IMPORT Std.BLAS;
IMPORT int.MatDims;
IMPORT Std.system.Thorlib;
Layout_Cell := Types.Layout_Cell;
Layout_Part := iTypes.Layout_Part;
Layout_Target := iTypes.Layout_Target;
Layout_Dims := iTypes.Layout_Dims;
value_t := Types.value_t;
dimension_t := Types.dimension_t;
OpType := iTypes.OpType;
work_item_t := Types.work_item_t;

emptyC := DATASET([], Layout_Cell);
SET OF value_t empty_array := [];
wi_id_list := RECORD
  work_item_t wi_id;
END;
/**
  * Extended Parallel Block Matrix Multiplication Module
  *
  * Implements: Result <- alpha * op(A)op(B) + beta * C.  op is No Transpose or Transpose.
  *
  * Multiplies two matrixes A and B, with an optional pre-multiply transpose for each
  * Optionally scales the product by the scalar "alpha".
  * Then adds an optional C matrix to the product after scaling C by the scalar "beta".
  *
  * A, B, and C are specified as DATASET(Layout_Cell), as is the Resulting matrix.
  * Layout_Cell describes a sparse matrix stored as a list of x, y, and value.
  *
  * This interface also provides a "Myriad" capability allowing multiple similar
  * operations to be performed on independent sets of matrixes in parallel.
  * This is done by use of the work-item id (wi_id) in each cell of the matrixes.
  * Cells with the same wi_id are considered part of the same matrix.
  * In the myriad form, each input matrix A, B, and (optionally) C can contain many
  * independent matrixes. The wi_ids are matched up such that each operation involves
  * the A, B, and C with the same wi_id.  A and B must therefore contain the same set
  * of wi_ids, while C is optional for any wi_id.  The same parameters: alpha, beta,
  * transposeA, and transposeB are used for all work-items.
  * The result will contain cells from all provided work-items. 
  *
  * Result has same shape as C if provided.  Note that matrixes are not explicitly
  * dimensioned.  The shape is determined by the highest value of x and y for each
  * work-item.
  *
  * @param transposeA		Boolean indicating whether matrix A should be transposed
  *							 before multiplying
  * @param transposeB		Same as above but for matrix B
  * @param alpha			Scalar multiplier for alpha * A * B
  * @param A_in				'A' matrix (multiplier) in Layout_Cell format
  * @param B_in				Same as above for the 'B' matrix (multiplicand)
  * @param C_in				Same as above for the 'C' matrix (addend). May be omitted.
  * @param beta				A scalar multiplier for beta * C, scales the C matrix before
  *							 addition. May be omitted.
  * @return                 Result matrix in Layout_Cell format.
  * @see                    PBblas/Types.Layout_Cell
  */
EXPORT DATASET(Layout_Cell) gemm(BOOLEAN transposeA, BOOLEAN transposeB,
			  value_t alpha,
              DATASET(Layout_Cell) A_in,
              DATASET(Layout_Cell) B_in,
              DATASET(Layout_Cell) C_in=emptyC,
              value_t beta=0.0) := FUNCTION
    
  nodes := Thorlib.nodes();

  // Calculate Matrix Dimensions
  // Note: These are all normalized for transposes (i.e. post transpose)
  // First calculate the raw dimensions of the matrixes (one per wi_id)
  // Transpose the dimensions if transposeA or transposeB
  A_dims_n := MatDims.FromCells(A_in, 'A');
  A_dims_t := MatDims.TransposeDims(A_dims_n);
  A_dims := IF(transposeA, A_dims_t, A_dims_n);
  B_dims_n := MatDims.FromCells(B_in, 'B');
  B_dims_t := MatDims.TransposeDims(B_dims_n);
  B_dims := IF(transposeB, B_dims_t, B_dims_n);
  C_dims := MatDims.FromCells(C_in, 'C');
  // Now use those dimensions to calculate the partition sizes.
  // Note that this produces partitioning schemes for A, B, and C for each wi_id.
  // The different matrixes are identified my their m_label ('A', 'B', 'C')
  part_dims := MatDims.PartitionedFromDimsForOp(OpType.multiply, A_dims+B_dims+C_dims);

  // We need to handle a special case optimization when a work-item represents
  // an inner-product multiplication (i.e. column block vector X row block vector)
  // where there is a single result partition.  First we need to separate the inner-
  // product case from the normal case work-items
  
  // Transform to detect inner-product work items
  wi_id_list get_IP_wi_ids(Layout_Dims l, Layout_Dims r) := TRANSFORM
    // It's an inner product if A is 1 x N and B is M x 1.  Exclude the case where
    // there is only one A and B block.
    wi_id := IF(l.row_blocks = 1
                AND l.col_blocks > 1
                AND r.col_blocks = 1, l.wi_id, SKIP);
    SELF.wi_id := wi_id; 
  END;
  
  // Separate the A, B, and C dimensions
  Apart_dims := part_dims(m_label='A');
  Bpart_dims := part_dims(m_label='B');
  Cpart_dims := part_dims(m_label='C');
  
  // Get the Inner-product work items
  IP_WIs := JOIN(Apart_dims, Bpart_dims, 
  				LEFT.wi_id = RIGHT.wi_id, get_IP_wi_ids(LEFT, RIGHT));
  SET OF work_item_t IPset := set(IP_WIs, wi_id);
  // Now that we have the partition dimensions for each matrix, we can convert
  // from cells to partitions
  Aparts_all := int.Converted.FromCells(Apart_Dims, A_in, transposeA);
  Bparts_all := int.Converted.FromCells(Bpart_Dims, B_in, transposeB);
  Cparts_all := int.Converted.FromCells(Cpart_Dims, C_in);
  // Extract the partitions for normal processing
  Aparts     := Aparts_all(wi_id NOT IN IPset);
  Bparts     := Bparts_all(wi_id NOT IN IPset);
  Cparts     := Cparts_all(wi_id NOT IN IPset);
  // Extract the partitions for Inner Product (IP) special case processing
  Aparts_IP  := Aparts_all(wi_id IN IPset);
  Bparts_IP  := Bparts_all(wi_id IN IPset);
  Cparts_IP  := Cparts_all(wi_id IN IPset);
  
  // Process the normal work-items
  
  // Extended part record has information about the opposite matrix (i.e. A vs B)
  part_ext := RECORD
    dimension_t repl_count;
    Layout_Part;
  END;
  
  // Convert partitions to targets.  Targets define pairs of partitions that need
  // to be multiplied and summed to create a single result partition.
  Layout_Target cvt(part_ext par, INTEGER c) := TRANSFORM
    isA               := par.m_label = 'A'; // Calculations for A and B are somewhat different
    s_block_row       := par.block_row;
    s_block_col       := par.block_col;
    row_blocks        := par.row_blocks;
    // Here we need the number of row blocks in the result so that we
    // can compute the target partition information.  If this is A,
    // then it is just A's row blocks.  If B, then we can use the repl_count
    // which will be contain A's row block count.
    result_row_blocks := IF(isA, row_blocks, par.repl_count);
    part_id_new_row   := (s_block_col-1) * result_row_blocks + c;
    part_id_new_col   := (c-1) * result_row_blocks + s_block_row;
    partition_id      := IF(isA, part_id_new_col, part_id_new_row);
    SELF.t_node_id    := (HASH32(par.wi_id) + partition_id-1) % nodes;
    SELF.t_part_id    := partition_id;
    SELF.t_block_row  := IF(isA, s_block_row, c);
    SELF.t_block_col  := IF(isA, c, s_block_col);
    SELF.t_term       := IF(isA, s_block_col, s_block_row);
    SELF.m_label      := par.m_label;
    SELF              := par;
  END;
  // We need to extend each partition record to carry information about
  // the opposite corresponding partition (i.e. A vs B).  We need to carry
  // the number of times to replicate each partition (from the opposite matrix).
  part_ext extend_parts(Layout_Part part, Layout_Dims other_dims) := TRANSFORM
    is_A := part.m_label = 'A';
    // Repl count for A is B's column blocks, and for B is A's row blocks.
  	SELF.repl_count := IF(is_A , other_dims.col_blocks, other_dims.row_blocks);
  	SELF := part;
  END;
  // Compose a set of targets, one for each partition of the result
  // Distribute all of the row and column partitions that need to
  // be multiplied (and ultimately added) for the result partition
  // to the same node.  Each result partition can thereby be computed
  // on a single node.
  // A copy of each cell in a row (column) goes to a column(row) (transpose)
  a_ext := JOIN(Aparts, Bpart_dims, LEFT.wi_id=RIGHT.wi_id, extend_parts(LEFT, RIGHT),
                       LOOKUP) : ONWARNING(4531, IGNORE);
  // Copy each partition of A to all of the nodes that need if for its computations
  a_work := NORMALIZE(a_ext, LEFT.repl_count, cvt(LEFT, COUNTER));
  a_dist := DISTRIBUTE(a_work, t_node_id);
  // Sort on each local node
  a_sort := SORT(a_dist, wi_id, t_part_id, t_term, LOCAL);
  // Copy each partition of B to all of the nodes that need if for its computations
  b_ext := JOIN(Bparts, Apart_dims, LEFT.wi_id=RIGHT.wi_id, extend_parts(LEFT, RIGHT),
                       LOOKUP) : ONWARNING(4531, IGNORE);
  b_work := NORMALIZE(b_ext, LEFT.repl_count, cvt(LEFT, COUNTER));
  b_dist := DISTRIBUTE(b_work, t_node_id);
  // Sort by the targets partition-id for later processing
  b_sort := SORT(b_dist, wi_id, t_part_id, t_term, LOCAL);
  
  // Function to Multiply pairs of partitions
  Layout_Part mul(Layout_Target a_part, Layout_Target b_part):=TRANSFORM
    part_id     := a_part.t_part_id;    //arbitrary choice
    part_a_cols := a_part.part_cols;
    part_a_rows := a_part.part_rows;
    part_b_rows := b_part.part_rows;
    part_c_rows := a_part.part_rows;
    part_c_cols := b_part.part_cols;
    part_c_row_blocks := a_part.row_blocks;
    part_c_col_blocks := b_part.col_blocks;
    part_c_first_row  := a_part.first_row;
    part_c_first_col  := b_part.first_col;
    k := part_a_cols;
    SELF.partition_id := part_id;
    SELF.wi_id        := a_part.wi_id; // arbitrary choice
    SELF.node_id      := a_part.t_node_id;
    SELF.block_row    := a_part.t_block_row;
    SELF.block_col    := a_part.t_block_col;
    SELF.first_row    := part_c_first_row;
    SELF.part_rows    := part_c_rows;
    SELF.first_col    := part_c_first_col;
    SELF.part_cols    := part_c_cols;
    SELF.m_label      := 'R';
    SELF.m_rows		  := a_part.m_rows;
    SELF.m_cols       := b_part.m_cols;
    SELF.row_blocks   := part_c_row_blocks;
    SELF.col_blocks   := part_c_col_blocks;
    SELF.mat_part     := BLAS.dgemm(FALSE, FALSE,
                                    part_c_rows, part_c_cols, k,
                                    alpha, a_part.mat_part, b_part.mat_part,
                                    0.0, empty_array);
  END;
  
  // Assemble pairs of partitions to be multiplied by joining on the partition-id
  //  (i.e. same result partition) and t_term, which aligns the proper column / row
  //  pairs within that result part (e.g. A col 1 with B row 1)
  ab_prod := JOIN(a_sort, b_sort,
					    LEFT.wi_id = RIGHT.wi_id AND 
					    LEFT.t_part_id=RIGHT.t_part_id AND 
					    LEFT.t_term=RIGHT.t_term,
					    mul(LEFT,RIGHT), LOCAL, NOSORT);

  // ab_prod contains a list of the products of each pair of partitions needed
  // to produce each of the result partitions on the local machine.
  // Next we can scale the corresponding partitions of C and place it in with the set 
  // of partitions to be added
  
  // Function to scale the local partitions of C by beta
  Layout_Part applyBeta(Layout_Part part) := TRANSFORM
    SELF.mat_part := BLAS.dscal(part.part_rows*part.part_cols,
                                beta, part.mat_part, 1);
    SELF          := part;
  END;
  
  // Local partitions of C matrix scaled by beta
  upd_C := PROJECT(Cparts, applyBeta(LEFT));

  // Function to sum all the parts that share the same result partition
  Layout_Part sumTerms(Layout_Part cumm, Layout_Part term) := TRANSFORM
    N := cumm.part_rows * cumm.part_cols;
//    N := map_c.part_rows(cumm.partition_id) * map_c.part_cols(cumm.partition_id);
    SELF.mat_part := BLAS.daxpy(N, 1.0, cumm.mat_part, 1, term.mat_part, 1);
    SELF := cumm;
  END; 
  // Sort the partitions so that all addends for the same result partition are
  //  adjacent (on each local system). Note that we insert the appropriate 
  //  partition of C into the mix to be added
  sorted_terms := SORT(upd_c+ab_prod, wi_id, partition_id, LOCAL);

  // Add all the pieces together for each result partition on the local system and we
  // have our answer. 
  rslt_parts := ROLLUP(sorted_terms, sumTerms(LEFT, RIGHT), wi_id, partition_id, LOCAL);

  // Process Inner Product work items
  
  // TRANSFORM to multiply corresponding partitions of A and B
  Layout_Part mulIP(Layout_Part a_part, Layout_Part b_part) := TRANSFORM
    // Multiply corresponding A and B part.  Relocate to partition 1 since the
    // result only has one partition for IP
    k := a_part.part_cols;
    m := a_part.part_rows;
    n := b_part.part_cols;
    SELF.mat_part := BLAS.dgemm(FALSE, FALSE, m, n, k,
                                alpha, a_part.mat_part, b_part.mat_part, 0.0);
    partition_id    := 1;
    SELF.node_id    := (HASH32(a_part.wi_id) + partition_id - 1) % nodes;
    SELF.partition_id := partition_id;
    SELF.block_row  := 1;
    SELF.block_col  := 1;
    SELF.first_row  := 1;
    SELF.first_col  := 1;
    SELF.part_rows  := m;
    SELF.part_cols  := n;
    SELF.row_blocks := 1;
    SELF.col_blocks := 1;
    SELF.m_label    := 'C';
    SELF.m_rows     := a_part.m_rows;
    SELF.m_cols     := b_part.m_cols;
    SELF.wi_id		:= a_part.wi_id;  // arbitrary -- same wi_id for both
  END;
  
  // Don't need to DISTRIBUTE the partitions for the dot product for inner product
  // case, since Apart1 will be multiplied by Bpart1, and so on.  The default
  // distribution is by wi_id and partition_id, so everything should already be
  // in the right place
  a_sort_IP := SORT(Aparts_IP, wi_id, partition_id, LOCAL);
  b_sort_IP := SORT(Bparts_IP, wi_id, partition_id, LOCAL);
  // Compute the dot products and move the results to partition1 (since there is
  // only one result partition for IP.
  dots   := JOIN(a_sort_IP, b_sort_IP,
                 LEFT.wi_id = RIGHT.wi_id AND
                 LEFT.partition_id=RIGHT.partition_id,
                 mulIP(LEFT, RIGHT), LOCAL, NOSORT) : ONWARNING(4531, IGNORE);;
  prod_IP   := DISTRIBUTE(dots, node_id);

  // Scale C by beta
  scaledC_IP := PROJECT(Cparts_IP, applyBeta(LEFT));
  sorted_terms_IP := SORT(scaledC_IP + prod_IP, wi_id, partition_id, LOCAL);
  // Sum the dot products and the C partition
  rslt_parts_IP := ROLLUP(sorted_terms_IP, sumTerms(LEFT,RIGHT), wi_id, partition_id, LOCAL);
  // END of Inner Product Section
  

  /**
    * The result matrix in cell form (i.e. Layout_Cell)
    *
    * @see	Std/PBblas/Types.Layout_Cell
    */
  // Return result for normal work-items plus inner-product work-items
  rslt := int.Converted.FromParts(rslt_parts & rslt_parts_IP);
  RETURN rslt;
END;