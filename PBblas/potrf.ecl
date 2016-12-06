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
Layout_Cell := Types.Layout_Cell;
Layout_Part := iTypes.Layout_Part;
Layout_Target := iTypes.Layout_Target;
OpType := iTypes.OpType;
Triangle := Types.Triangle;
Upper:= Types.Triangle.Upper;
Lower:= Types.Triangle.Lower;
Diagonal := Types.Diagonal;
iTypes.matrix_t empty_mat := [];
dimension_t := Types.dimension_t;

/**
  * Implements Cholesky factorization of A = U**T * U if Triangular.Upper requested
  * or A = L * L**T if Triangualr.Lower is requested.
  * The matrix A must be symmetric positive definite.
  *  | A11   A12 |      |  L11   0   |    | L11**T     L21**T |
  *  | A21   A22 |  ==  |  L21   L22 | *  |  0           L22  |
  *
  *                     | L11*L11**T          L11*L21**T      |
  *                 ==  | L21*L11**T  L21*L21**T + L22*L22**T |
  *
  * So, use Cholesky on the first block to get L11.
  *     L21 = A21*L11**T**-1   which can be found by dtrsm on each column block
  *     A22' is A22 - L21*L21**T
  * Based upon PB-BLAS: A set of parallel block basic linear algebra subprograms
  * by Choi and Dongarra
  *
  * This module supports the "Myriad" style interface, allowing many independent problems
  * to be worked on at once.  The A matrix can contain multiple matrixes to be factored,
  * indicated by different values for work-item id (wi_id).  
  *
  * @param tri  Types.Triangle enumeration indicating whether we are looking for the Upper
  *             or the Lower factor
  * @param A_in The matrix or matrixes to be factored in Types.Layout_Cell format
  * @return     Triangular matrix in Layout_Cell format
  * @see Std.PBblas.Types.Layout_Cell
  * @see Std.PBblas.Types.Triangle
  *
  */
EXPORT DATASET(Layout_Cell) potrf(Triangle tri, DATASET(Layout_Cell) A_in) := FUNCTION
  nodes := Thorlib.nodes();
  // LOOP body
  loopBody(DATASET(Layout_Part) parts, UNSIGNED4 rc_pos, dimension_t max_a_dim) := FUNCTION
    // Select diagonal block, use dpotf2 in PROJECT to produce L11 or U11
    A_11 := SORTED(parts(block_row=rc_pos AND block_col=rc_pos), partition_id, wi_id);
    Layout_Part factorBlock(Layout_Part part) := TRANSFORM
      r := part.part_rows;
      // dpotf2 throws error if factoring fails
      SELF.mat_part := BLAS.dpotf2(tri, r, part.mat_part);
      SELF := part;
    END;
    cornerMatrix := PROJECT(A_11, factorBlock(LEFT));
    // Use PB_DTRSM with L11 to get L21 (U12)
    A_21 := parts(block_col=rc_pos AND block_row>rc_pos);
    A_12 := parts(block_row=rc_pos AND block_col>rc_pos);
   Layout_Part updateSub(Layout_Part outPart, Layout_Part corner) := TRANSFORM
      side := IF(tri=Lower, Types.Side.xA, Types.Side.Ax);
      part_rows := outPart.part_rows;
      part_cols := outPart.part_cols;
      lda       := corner.part_rows;
      SELF.mat_part := BLAS.dtrsm(side, tri, TRUE, Diagonal.NotUnitTri,
                                  part_rows, part_cols, lda, 1.0,
                                  corner.mat_part, outPart.mat_part);
      SELF := outPart;
    END;
    L_21 := JOIN(A_21, cornerMatrix, LEFT.block_col=RIGHT.block_col 
                 AND LEFT.wi_id = RIGHT.wi_id,
                updateSub(LEFT,RIGHT), LOOKUP);
    U_12 := JOIN(A_12, cornerMatrix, LEFT.block_row=RIGHT.block_row
                 AND LEFT.wi_id = RIGHT.wi_id,
                updateSub(LEFT, RIGHT), LOOKUP);
    edgeMatrix := IF(tri=Lower, L_21, U_12);
    // Prep for rank update
    Layout_Target stampC(Layout_Part part) := TRANSFORM
      SELF.t_part_id    := part.partition_id;
      SELF.t_node_id    := part.node_id;
      SELF.t_block_row  := part.block_row;
      SELF.t_block_col  := part.block_col;
      SELF.t_term       := 3;   // C
      SELF              := part;
    END;
    Term3_d := PROJECT(parts(block_row>rc_pos AND block_col>rc_pos), stampC(LEFT));
    // Replicate  L21(U12) to get new sub-matrix
    Layout_Target replicate(Layout_Part part, dimension_t tr,
                            dimension_t tc, UNSIGNED term) := TRANSFORM
      // Normalize count may be greater than our size (because of myriad)
      // Skip if we are outside of our bounds
      valid             := tr <= part.row_blocks AND tc <= part.col_blocks;
      target_part       := IF(valid, ((tc-1) * part.row_blocks) + tr, SKIP);
      SELF.t_part_id    := target_part;
      SELF.t_node_id    := (HASH32(part.wi_id) + target_part-1) % nodes;
      SELF.t_block_row  := tr;
      SELF.t_block_col  := tc;
      SELF.t_term       := term;
      SELF              := part;
    END;
    X_L_21   := NORMALIZE(L_21, max_a_dim-rc_pos,
                          replicate(LEFT, LEFT.block_row, rc_pos+COUNTER, 1));
    X_L_21T  := NORMALIZE(L_21, max_a_dim-rc_pos,
                          replicate(LEFT, rc_pos+COUNTER, LEFT.block_row, 2));
    X_U_12   := NORMALIZE(U_12, max_a_dim-rc_pos,
                          replicate(LEFT, rc_pos+COUNTER, LEFT.block_col, 2));
    X_U_12T  := NORMALIZE(U_12, max_a_dim-rc_pos,
                          replicate(LEFT, LEFT.block_col, rc_pos+COUNTER, 1));
    Term1_d  := IF(tri=Lower, X_L_21, X_U_12T);
    Term2_d  :=IF(tri=Lower, X_L_21T, X_U_12);
    // Bring together sub-matrix parts and perform rank update
    Layout_Target updMat(Layout_Target lr, DATASET(Layout_Target) rws):=TRANSFORM
      part_id           := lr.t_part_id;
      block_rows        := ROUNDUP(lr.m_rows / lr.row_blocks);
      block_cols        := ROUNDUP(lr.m_cols / lr.col_blocks);
      first_row         := ((part_id-1)  %  lr.row_blocks) * block_rows + 1;
      first_col         := ((part_id-1) DIV lr.row_blocks) * block_cols + 1;
      num_rows          := MIN([block_rows, lr.m_rows - first_row + 1]);
      num_cols          := MIN([block_cols, lr.m_cols - first_col + 1]);
      have_a            := EXISTS(rws(t_term=1));
      idA_proto         := rws(t_term=1)[1];
      idA               := idA_proto.partition_id;
      have_b            := EXISTS(rws(t_term=2));
      multiplyTerms     := have_a AND have_b;
      tranA             := IF(tri=Upper, TRUE, FALSE);
      tranB             := IF(tri=Lower, TRUE, FALSE);
      have_c            := EXISTS(rws(t_term=3));
      matrix_c          := IF(have_c, rws(t_term=3)[1].mat_part, empty_mat);
      matrix_a          := rws(t_term=1)[1].mat_part;
      matrix_b          := rws(t_term=2)[1].mat_part;
      idA_part_rows     := idA_proto.part_rows;
      idA_part_cols     := idA_proto.part_cols;
      inside            := IF(tri=Upper, idA_part_rows, idA_part_cols);
      SELF.partition_id := part_id;
      SELF.node_id      := (HASH32(lr.wi_id) + part_id-1) % nodes;
      SELF.block_row    := lr.t_block_row;
      SELF.block_col    := lr.t_block_col;
      SELF.first_row    := first_row;
      SELF.first_col    := first_col;
      SELF.part_rows    := num_rows;
      SELF.part_cols    := num_cols;
      SELF.mat_part     := IF(multiplyTerms,
                              BLAS.dgemm(tranA, tranB, num_rows, num_cols, inside,
                                        -1.0, matrix_a, matrix_b, 1.0, matrix_c),
                              matrix_c);
      SELF              := lr;
    END;
    recordSets1 := SORT(DISTRIBUTE(Term1_d+Term2_d+Term3_d, t_node_id), t_part_id, wi_id, LOCAL);
    recordSets := GROUP(recordSets1, t_part_id, wi_id, LOCAL);
    updatedSub := ROLLUP(recordSets, GROUP, updMat(LEFT, ROWS(LEFT)));
    subMatrix  := PROJECT(updatedSub, Layout_Part);
     // Bring the three pieces of the triangle together:  the corner (L11), the edge 
    // (either L21, or L12), and the remaining sub matrix (L22).
    rslt       := MERGE(cornerMatrix, edgeMatrix, subMatrix, SORTED(partition_id, wi_id), LOCAL);
    RETURN rslt;
  END;  // End LOOP

  // Get the dimensions of the matrices
  a_dims := MatDims.FromCells(A_in);
  // Get partitioned dimensions
  a_part_dims := MatDims.PartitionedFromDimsForOp(OpType.square, a_dims);
  // Convert from cells to partitions
  a_parts := Converted.FromCells(a_part_dims, A_in);
  // Drop out parts that are not needed
  work_parts := SORTED(a_parts((tri=Upper AND block_row<=block_col) OR
                         (tri=Lower AND block_col<=block_row)), partition_id, wi_id);
  // Get the dimension of the biggest matrix across all work-items
  max_a_dim := MAX(a_part_dims, a_part_dims.row_blocks);
  // Compute the requested triangle
  triangle_parts := LOOP(work_parts, max_a_dim,
                       COUNTER<=LEFT.block_row AND COUNTER<=LEFT.block_col,
                       loopBody(ROWS(LEFT), COUNTER, max_a_dim));
  part_rslt := triangle_parts;
  // Convert from partitions back to cells
  rslt := Converted.FromParts(part_rslt);
  RETURN rslt;
END;
