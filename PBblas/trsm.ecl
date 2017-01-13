/*##############################################################################
## HPCC SYSTEMS software Copyright (C) 2016 HPCC Systems®.  All rights reserved.
############################################################################## */

IMPORT $ as PBblas;
IMPORT PBblas.Types;
IMPORT Std.BLAS;
IMPORT PBblas.internal as int;
IMPORT int.Types as iTypes;
IMPORT int.MatDims;
IMPORT int.Converted;
IMPORT std.system.Thorlib;
value_t   := Types.value_t;
matrix_t  := iTypes.matrix_t;
Triangle  := Types.Triangle;
Lower     := Types.Triangle.Lower;
Upper     := Types.Triangle.Upper;
Diagonal  := Types.Diagonal;
Side      := Types.Side;
Layout_Part := iTypes.Layout_Part;
Layout_Cell := Types.Layout_Cell;
Layout_Dims := iTypes.Layout_Dims;
Layout_Target := iTypes.Layout_Target;
dimension_t := Types.dimension_t;
OpType   := iTypes.OpType;
BaseTerm := 1;
RightTerm := 3;
LeftTerm := 2;
/**
  * Partitioned block parallel triangular matrix solver.
  *
  * Solves for X using: AX = B or XA = B
  * A is is a square triangular matrix, X and B have the same dimensions.
  * A may be an upper triangular matrix (UX = B or XU = B), or a lower
  * triangular matrix (LX = B or XL = B).
  * Allows optional transposing and scaling of A.
  * Partially based upon an approach discussed by MJ DAYDE, IS DUFF, AP CERFACS.
  * A Parallel Block implementation of Level-3 BLAS for MIMD Vector Processors
  * ACM Tran. Mathematical Software, Vol 20, No 2, June 1994 pp 178-193
  * and other papers about PB-BLAS by Choi and Dongarra
  *
  * This module supports the "Myriad" style interface, allowing many independent problems
  * to be worked on at once.  Corresponding A and B matrixes are related by a common
  * work-item identifier (wi_id) within each cell of the matrix.  The returned X matrix
  * will contain cells for the same set of work-items as specified for the A and B matrices.
  *
  * @param s     Types.Side enumeration indicating whether we are solving AX = B or XA = B
  * @param tri   Types.Triangle enumeration indicating whether we are solving an Upper or
  *              Lower triangle.
  * @param transposeA Boolean indicating whether or not to transpose the A matrix before
  *                   solving
  * @param diag  Types.Diagonal enumeration indicating whether A is a unit matrix or not 
  * @param alpha Multiplier to scale A
  * @param A_in  The A matrix in Layout_Cell format
  * @param B_in  The B matrix in Layout_Cell format
  * @return      X solution matrix in Layout_Cell format
  * @see         Types.Layout_Cell
  * @see         Types.Triangle
  * @see         Types.Side
  */
EXPORT DATASET(Layout_Cell) trsm(Side s, Triangle tri, BOOLEAN transposeA, Diagonal diag,
                value_t alpha,
                DATASET(Layout_Cell) A_in,
                DATASET(Layout_Cell) B_in) := FUNCTION

  nodes := Thorlib.nodes();
  // Get the basic A matrix dimensions
  a_dims_n := MatDims.FromCells(A_in, 'A');
  a_dims_t := MatDims.TransposeDims(a_dims_n);
  a_dims := IF(transposeA, a_dims_t, a_dims_n);
  // Get the basic B matrix dims
  b_dims := MatDims.FromCells(B_in, 'B');
  op_type := IF(s = Side.Ax, OpType.solve_Ax, OpType.solve_xA);
  // Get partitioning schemes for A and B
  part_dims := MatDims.PartitionedFromDimsForOp(op_type, a_dims + b_dims);
  a_part_dims := part_dims(m_label='A');
  b_part_dims := part_dims(m_label='B');
  // Convert A and B to partitions.  Transpose A in the process if requested
  a_parts := SORTED(Converted.FromCells(a_part_dims, A_in, transposeA), partition_id, wi_id);
  b_parts := SORTED(Converted.FromCells(b_part_dims, B_in), partition_id, wi_id);
  // Definitions for four cases to be handled
  Upper_xA := s=Side.xA AND tri=Upper;
  Upper_Ax := s=Side.Ax AND tri=Upper;
  Lower_xA := s=Side.xA AND tri=Lower;
  Lower_Ax := s=Side.Ax AND tri=Lower;
  // Extend A partitions to include B's row_blocks.  We will need this later and
  // is probably best to do here in one pass
  Layout_Part_ext := RECORD(Layout_Part)
    dimension_t b_row_blocks := 0;
    dimension_t b_col_blocks := 0;
  END;
  Layout_Part_ext extend_a(Layout_Part l, Layout_Dims r) := TRANSFORM
    SELF.b_row_blocks := r.row_blocks;
    SELF.b_col_blocks := r.col_blocks;
    SELF              := l;
  END;
  a_parts_ext1 := JOIN(a_parts, b_part_dims, LEFT.wi_id = RIGHT.wi_id, extend_a(LEFT, RIGHT),
                       LOOKUP) : ONWARNING(4531, IGNORE);
  a_parts_ext := SORTED(a_parts_ext1, partition_id, wi_id);
  // Loop body, by diagonal, right to left for upper and left to right for lower
  loopBody(DATASET(Layout_Part) parts, UNSIGNED4 loop_c, dimension_t max_a_dim) := FUNCTION
    // Process is as follows:
    // - Solve each block at the current row or column position with its diagonal in A
    //   This forms the base (starting point) for the solution
    // - Subtract from the base every earlier solution multiplied by its corresponding 
    //   A coefficient.
    
    // reverse implies left-to-right for column solutions or bottom-to-top for row solutions
    reverse := IF(tri=Upper, s=Side.Ax, s=Side.xA);
    // rc_pos is the current row or column index.  It runs forward or backward depending
    //  on setting of "reverse" above.
    rc_pos  := IF(reverse, 1 + max_a_dim - loop_c, loop_c);
    // remaining indicates how many more rows there are to process.
    remaining := max_a_dim - loop_c;  // Rows or Columns same
    
    // Transform to solve each block
    Layout_Part solveBlock(Layout_Part b_rec, Layout_Part a_rec) := TRANSFORM
      b_part_rows := b_rec.part_rows;
      b_part_cols := b_rec.part_cols;
      a_part_rows := a_rec.part_rows;
      SELF.mat_part := BLAS.dtrsm(s, tri, FALSE, diag,
                                  b_part_rows,
                                  b_part_cols,
                                  a_part_rows,
                                  alpha, a_rec.mat_part, b_rec.mat_part);
      SELF := b_rec;
    END;

    // Solve each of the B blocks at the current index with the diagonal
    // of A for that row or column. 
    solved := JOIN(parts, a_parts(block_row=rc_pos AND block_col=rc_pos),
                   LEFT.wi_id = RIGHT.wi_id
                   AND ((s=Side.Ax AND LEFT.block_row=RIGHT.block_row)
                   OR (s=Side.xA AND LEFT.block_col=RIGHT.block_col)),
                   solveBlock(LEFT, RIGHT), LOOKUP) : ONWARNING(4531, IGNORE);
                   
    // Base parts stay in place, just need routing for transform
    Layout_Target prepBase(Layout_Part base) := TRANSFORM
      SELF.t_part_id  := base.partition_id;
      SELF.t_node_id  := base.node_id;
      SELF.t_block_row:= base.block_row;
      SELF.t_block_col:= base.block_col;
      SELF.t_term     := BaseTerm;
      SELF            := base;
    END;
    // The blocks at the current rc_pos have been solved.  The rest need to be 
    // updated based on this solution.
    // Solved blocks not in update, loop filter has removed prior solves
    // Also, when we are going in reverse, we are going to skip any 
    // blocks that are lower than the rc_pos.  We don't want to update until
    // after we have processed the first diagonal block.
    parts4update := parts((s=Side.Ax AND block_row <> rc_pos AND (rc_pos <= row_blocks))
                         OR (s=Side.xA AND block_col <> rc_pos AND (rc_pos <= col_blocks)));
    // Save any skipped records for next time through.
    skipped := parts((s=Side.Ax AND rc_pos > row_blocks) OR (s=Side.xA AND rc_pos > col_blocks));
    // All later blocks get their base established by starting with their corresponding
    // B value.
    need_upd := SORTED(PROJECT(parts4update, prepBase(LEFT)), t_part_id, wi_id);

    // Functions to replicate B and A blocks for propagation to their targets
    // Replicate B blocks Function
    Layout_Target repPartB(Layout_Part inPart, dimension_t repl) := TRANSFORM
      row_base          := IF(s=Side.Ax, rc_pos, 0);
      col_base          := IF(s=Side.xA, rc_pos, 0);
      offset            := IF(reverse, -repl, repl);
      t_row             := IF(s=Side.Ax,row_base + offset, inPart.block_row);
      t_col             := IF(s=Side.xA, col_base + offset, inPart.block_col);
      // Skip if we're outside our bounds due to use of max_a_dim in the normalize
      valid             := t_row <= inPart.row_blocks AND t_col <= inPart.col_blocks;
      b_row_blocks      := IF(valid, inPart.row_blocks, SKIP);
      t_part            := ((t_col-1) * b_row_blocks) + t_row;
      SELF.t_part_id    := t_part;
      SELF.t_node_id    := (HASH32(inPart.wi_id) + t_part-1) % nodes;    
      SELF.t_block_row  := t_row;
      SELF.t_block_col  := t_col;
      SELF.t_term       := IF(s=Side.Ax, RightTerm, LeftTerm);
      SELF              := inPart;
    END;
    // Replicate A blocks Function
    Layout_Target repPartA(Layout_Part_ext inPart, dimension_t repl) := TRANSFORM
      t_row             := IF(s=Side.xA, repl, inPart.block_row);
      t_col             := IF(s=Side.Ax, repl, inPart.block_col);
      // We need B's row blocks amd col_blocks here, which we couldn't normally 
      // get from A, which is why we extended A to include B's block counts.
	  b_row_blocks      := inPart.b_row_blocks;
	  b_col_blocks      := inPart.b_col_blocks;
      // Skip if we're outside our bounds due to use of max_a_dim in the normalize
      valid             := t_row <= b_row_blocks AND t_col <= b_col_blocks;
      t_part            := IF(valid, ((t_col-1) * b_row_blocks) + t_row, SKIP);
      SELF.t_part_id    := t_part;
      SELF.t_node_id    := (HASH32(inPart.wi_id) + t_part-1) % nodes;    
      SELF.t_block_row  := t_row;
      SELF.t_block_col  := t_col;
      SELF.t_term       := IF(s=Side.Ax, LeftTerm, RightTerm);
      SELF              := inPart;
    END;
    // Replicate each solved block to all remaining rows or columns.  These will
    // be combined with (i.e. multiplied by) the corresponding A coefficients, and
    // subtracted from the base for that row or column.
    s0_repl  := NORMALIZE(solved, remaining, repPartB(LEFT, COUNTER));
    replSolv := SORT(DISTRIBUTE(s0_repl, t_node_id), t_part_id, wi_id, LOCAL);
    // Replicate the A blocks and route to the same target partition id as the 
    // corresponding solved blocks.  In the reverse cases, we eliminate any work-items
    // where we haven't reached the first solved block.
    neededCf := a_parts_ext((Upper_Ax AND block_col=rc_pos AND block_row<rc_pos AND rc_pos <= row_blocks )
                       OR (Lower_Ax AND block_col=rc_pos AND block_row>rc_pos)
                       OR (Upper_xA AND block_row=rc_pos AND block_col>rc_pos)
                       OR (Lower_xA AND block_row=rc_pos AND block_col<rc_pos AND rc_pos <= row_blocks));
    c0_repl  := NORMALIZE(neededCf, max_a_dim, repPartA(LEFT, COUNTER));
    replCoef := SORT(DISTRIBUTE(c0_repl, t_node_id), t_part_id, wi_id, LOCAL);

    // Transform to multiply each solved block by its A coefficient and subract from
    // the base.
    Layout_Target updatePart(Layout_Target l, DATASET(Layout_Target) blocks) := TRANSFORM
      matrix_t EmptyMat := [];
      have_lft:= EXISTS(blocks(t_term = LeftTerm));
      have_rgt:= EXISTS(blocks(t_term = RightTerm));
      do_mult := have_lft AND have_rgt;
      have_base  := EXISTS(blocks(t_term=BaseTerm));
      // We need dimension information about B matrix in order to calc the following.
      // We know that the base term and either the right or left term will be derived 
      // from B, so we can use it's dimension info.  The partition id will be the same
      // for all blocks, but the B will give us more dimension info.
      // In the event that there is no B part, we'll skip, since the partition will
      // always be zeros in that case.
      have_B_term := IF(s=Side.Ax, have_lft, have_rgt);
      B_term := IF(s=Side.Ax, blocks(t_term=RightTerm)[1], blocks(t_term=LeftTerm)[1]);
      valid := IF(have_base OR have_B_term, TRUE, SKIP);
      proto := IF(valid AND have_B_term, B_term, blocks(t_term=BaseTerm)[1]);
      base_set   := IF(have_base, blocks(t_term=BaseTerm)[1].mat_part, EmptyMat);
      lft_set := blocks(t_term=LeftTerm)[1].mat_part;
      lft_cols:= blocks(t_term=LeftTerm)[1].part_cols;
      rgt_set := blocks(t_term=RightTerm)[1].mat_part;
      part_id := proto.t_part_id;   //all records have same value
      SELF.node_id  := proto.t_node_id; // all records have the same
      SELF.partition_id := part_id; 
      block_rows := ROUNDUP(proto.m_rows / proto.row_blocks);
      block_cols := ROUNDUP(proto.m_cols / proto.col_blocks);
      first_row  := ((part_id-1)  %  proto.row_blocks) * block_rows + 1;
      first_col  := ((part_id-1) DIV proto.row_blocks) * block_cols + 1;
      SELF.block_row  := proto.t_block_row;
      SELF.block_col  := proto.t_block_col;
      SELF.first_row  := first_row;
      SELF.first_col  := first_col;
      part_rows  := MIN([block_rows, proto.m_rows - first_row + 1]);
      part_cols  := MIN([block_cols, proto.m_cols - first_col + 1]);
      SELF.part_rows  := part_rows;
      SELF.part_cols  := part_cols;
      // Note that dgemm here multiplies the current solution by the corresponding A 
      // coefficient, negates it (i.e. -1/alpha) and adds to the current B value.
      SELF.mat_part   := IF(do_mult,
                            BLAS.dgemm(FALSE, FALSE,
                                    part_rows,   // M
                                    part_cols,   // N
                                    lft_cols,                   // K
                                    -1/alpha, lft_set, rgt_set, 1.0, base_set),
                            base_set);
      SELF.t_node_id  := proto.t_node_id;
      SELF.t_part_id  := proto.t_part_id;
      SELF.t_block_row:= proto.t_block_row;
      SELF.t_block_col:= proto.t_block_col;
      SELF.t_term     := proto.t_term;
      SELF := proto;
    END;
    // Merge all of the targets for each partition
    // Need_upd has the base for each partition (original B value)
    // ReplSolv has the earlier solve to be multiplied by the corresponding A coefficients.
    // and subtracted from the base
    // ReplCoef has the A coefficients to be multiplied with the previous solved blocks.
//    inpSet := MERGE(need_upd, replCoef, replSolv, SORTED(t_part_id, wi_id), LOCAL);
    inpSet := MERGE(need_upd, replCoef, replSolv, SORTED(t_part_id, wi_id), LOCAL);
    // For each non-solved partition-id, multiply each A coefficient and its 
    // corresponding solved
    // block and negate to subtract the term from the base.
    inpSetGrouped := GROUP(inpSet, t_part_id, wi_id, LOCAL);
    updated := ROLLUP(inpSetGrouped, GROUP, updatePart(LEFT, ROWS(LEFT)));
    // assemble the revised parts
    // Convert from target to partition.  Targets should already be distributed
    // correctly based on node_id, so shouldn't need to re-distribute.
    parts_updated := PROJECT(updated, Layout_Part);
    // Each block was either updated or solved or skipped.  Return them all.
    rslt := SORT(parts_updated + solved + skipped, partition_id, wi_id, LOCAL);
 	
    RETURN rslt;
  END;  // loopBody
  // Maximum dimension of A for all work-items
  max_a_dim := MAX(a_part_dims, a_part_dims.row_blocks); 

  // Run the solver
  // Each loop runs one row or column of the solution.  The four variants are:
  // Lower_Ax -- LX = B : Down  -- Solve rows of X from top to bottom
  // Lower_xA -- XL = B : Left  -- Solve columns of X from right to left
  // Upper_Ax -- UX = B : Up    -- Solve rows of X from bottom to top
  // Upper_xA -- XU = B : Right -- Solve columns of X from left to right
  // where L := A is a Lower triangular matrix and U := A is a Upper triangular
  // matrix.  X is the result being solved for.
  // Since A and B may contain many separate matrixes (via myriad interface), use
  // the loop-count of the largest A matrix.  For any smaller matrixes we won't 
  // find any work until we are in range of its rows or columns.
  x_parts := LOOP(b_parts, max_a_dim,  // A is square, so xA and Ax same count
          (Upper_Ax AND LEFT.block_row <= 1 + max_a_dim - COUNTER) OR
          (Lower_Ax AND LEFT.block_row >= COUNTER) OR
          (Upper_xA AND LEFT.block_col >= COUNTER) OR
          (Lower_xA AND LEFT.block_col <= 1 + max_a_dim - COUNTER),
          loopBody(ROWS(LEFT), COUNTER, max_a_dim));
  // Convert from partitions back to cells
  x_cells := Converted.FromParts(x_parts);
  return x_cells;
END;