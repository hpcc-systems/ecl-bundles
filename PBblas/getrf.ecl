/*##############################################################################
## HPCC SYSTEMS software Copyright (C) 2016 HPCC Systems®.  All rights reserved.
############################################################################## */

IMPORT $ as PBblas;
IMPORT PBblas.Types;
IMPORT PBblas.internal as int;
IMPORT int.Types as iTypes;
IMPORT Std.BLAS;
IMPORT int.MatDims;
IMPORT std.system.Thorlib;
Layout_Cell := Types.Layout_Cell;
Layout_Part := iTypes.Layout_Part;
Layout_Target := iTypes.Layout_Target;
OpType := iTypes.OpType;
Triangle := Types.Triangle;
Upper:= Types.Triangle.Upper;
Lower:= Types.Triangle.Lower;
Diagonal := Types.Diagonal;
Side := Types.Side;
iTypes.matrix_t empty_mat := [];
dimension_t := Types.dimension_t;
Term := ENUM(UNSIGNED1, LeftTerm=1, RghtTerm=2, BaseTerm=3);

/**
  * LU Factorization
  *
  * Splits a matrix into Lower and Upper triangular factors
  *
  * Produces composite LU matrix for the diagonal
  * blocks.  Iterates through the matrix a row of blocks and column of blocks at
  * a time.  Partition A into M block rows and N block columns.  The A11 cell is a
  * single block.  A12 is a single row of blocks with N-1 columns.  A21 is a single
  * column of blocks with M-1 rows.  A22 is a sub-matrix of M-1 x N-1 blocks.
  *   | A11   A12 |      |  L11   0   |    | U11        U12    |
  *   | A21   A22 |  ==  |  L21   L22 | *  |  0         U22    |
  * 
  *                      | L11*U11             L11*U12         |
  *                  ==  | L21*U11         L21*U12 + L22*U22   |
  *
  * Based upon PB-BLAS: A set of parallel block basic linear algebra subprograms
  * by Choi and Dongarra
  *
  * This module supports the "Myriad" style interface, allowing many independent problems
  * to be worked on at once.  The A matrix can contain multiple matrixes to be factored,
  * indicated by different values for work-item id (wi_id).
  *
  * Note:  The returned matrix includes both the upper and lower factors.
  *        This matrix can be used directly by trsm which will only use
  *        the part indicated by trsm's 'triangle' parameter (i.e. upper
  *        or lower).  To extract the upper or lower triangle explicitly
  *        for other purposes, use the ExtractTri function.
  *
  * @param A    The input matrix in Types.Layout_Cell format
  * @return     Resulting factored matrix in Layout_Cell format
  * @see        Types.Layout_Cell
  * @see		ExtractTri
  */
EXPORT DATASET(Layout_Cell) getrf(DATASET(Layout_Cell) A) := FUNCTION
  nodes := Thorlib.nodes();
  // Loop body
  loopBody(DATASET(Layout_Part) parts, UNSIGNED4 rc_pos, 
      dimension_t max_row_blocks, dimension_t max_col_blocks) := FUNCTION
    // Select diagonal block, use dgetf2 in PROJECT to produce L11 and U11
    A_11 := parts(block_row=rc_pos AND block_col=rc_pos);
    
    // Transform to factor a single block
    Layout_Part factorBlock(Layout_Part part) := TRANSFORM    
      m := part.part_rows;
      n := part.part_cols;
      // dgetf2 throws error if factoring fails
      SELF.mat_part := BLAS.dgetf2(m, n, part.mat_part);
      SELF := part;
    END;
    newCorner := SORTED(PROJECT(A_11, factorBlock(LEFT)), partition_id, wi_id);
    // The dtrsm routine will work composite matrix, no need to extract
    Layout_Part divide(Layout_Part a_part, Layout_Part f_part) := TRANSFORM
      SELF.mat_part := IF(a_part.block_col=rc_pos,
                  BLAS.dtrsm(Side.xA, Upper, FALSE, Diagonal.NotUnitTri,
                             a_part.part_rows, a_part.part_cols, f_part.part_rows,
                             1.0, f_part.mat_part, a_part.mat_part),
                  BLAS.dtrsm(Side.Ax, Lower, FALSE, Diagonal.UnitTri,
                             a_part.part_rows, a_part.part_cols, f_part.part_rows,
                             1.0, f_part.mat_part, a_part.mat_part));
      SELF := a_part;
    END;
    // Generate L21 and U12 by dividing by the corner block L11
    newRow := JOIN(parts(block_col>rc_pos), newCorner,
                   LEFT.block_row=RIGHT.block_row AND LEFT.wi_id = RIGHT.wi_id,
                   divide(LEFT, RIGHT), LOOKUP);
    newCol := JOIN(parts(block_row>rc_pos), newCorner,
                   LEFT.block_col=RIGHT.block_col AND LEFT.wi_id = RIGHT.wi_id,
                   divide(LEFT, RIGHT), LOOKUP);
    // Outer row and column updated.  Now update the sub-matrix.
    Layout_Target stamp(Layout_Part p, dimension_t tr, dimension_t tc, Term trm) := TRANSFORM
      t_part := (tc-1) * p.row_blocks + tr;
      is_valid := tr <= p.row_blocks AND tc <= p.col_blocks;
      SELF.t_node_id := IF(is_valid, (HASH32(p.wi_id) + t_part-1) % nodes, SKIP);
      SELF.t_part_id := t_part;
      SELF.t_block_row := tr;
      SELF.t_block_col := tc;
      SELF.t_term := trm;
      SELF := p;
    END;
    // Now do the sub-matrix L22
    // Base parts contains the original value of each cell
    baseParts    := PROJECT(parts(block_row>rc_pos AND block_col>rc_pos),
                         stamp(LEFT, LEFT.block_row, LEFT.block_col, Term.BaseTerm));
    // Col parts extends each L21 part across the entire row
    colParts     := NORMALIZE(newCol, max_col_blocks-rc_pos,
                         stamp(LEFT, LEFT.block_row, rc_pos+COUNTER, Term.LeftTerm));
    // Row parts extends each U12 part down the entire column
    rowParts     := NORMALIZE(newRow, max_row_blocks-rc_pos,
                         stamp(LEFT, rc_pos+COUNTER, LEFT.block_col, Term.RghtTerm));
    // Transform to multiply the left and right terms and subract from the base
    Layout_Target update(DATASET(Layout_Target) p) := TRANSFORM
      haveBase := EXISTS(p(t_term=Term.BaseTerm));
      haveLeft := EXISTS(p(t_term=Term.LeftTerm));
      haveRght := EXISTS(p(t_term=Term.RghtTErm));
      doMultiply := haveLeft AND haveRght;
      proto    := p[1];  // All relate to the same partition.  Use the first as prototype
      node_id  := proto.t_node_id;
      part_id  := proto.t_part_id;
      block_row:= proto.t_block_row;
      block_col:= proto.t_block_col;
      block_rows := ROUNDUP(proto.m_rows / proto.row_blocks);
      block_cols := ROUNDUP(proto.m_cols / proto.col_blocks);
      first_row  := ((part_id-1)  %  proto.row_blocks) * block_rows + 1;
      first_col  := ((part_id-1) DIV proto.row_blocks) * block_cols + 1;
      inside_term := p(t_term=Term.RghtTerm)[1];
      inside   := inside_term.part_rows;
      num_rows  := MIN([block_rows, proto.m_rows - first_row + 1]);
      num_cols  := MIN([block_cols, proto.m_cols - first_col + 1]);
      BaseMat  := p(t_term=Term.BaseTerm)[1].mat_part;
      LeftMat  := p(t_term=Term.LeftTerm)[1].mat_part;
      RghtMat  := p(t_term=Term.RghtTerm)[1].mat_part;
      SELF.node_id      := node_id;
      SELF.partition_id := part_id;
      SELF.block_row    := block_row;
      SELF.block_col    := block_col;
      SELF.first_row    := first_row;
      SELF.first_col    := first_col;
      SELF.part_rows    := num_rows;
      SELF.part_cols    := num_cols;
      SELF.mat_part     := IF(doMultiply,
                              BLAS.dgemm(FALSE, FALSE, num_rows, num_cols, inside,
                                         -1.0, LeftMat, RghtMat,
                                         IF(haveBase, 1.0, 0.0), BaseMat),
                              BaseMat);
      SELF.t_node_id  := node_id;
      SELF.t_part_id  := part_id;
      SELF.t_block_row:= block_row;
      SELF.t_block_col:= block_col;
      SELF.t_term     := Term.BaseTerm;
      SELF            := proto;
    END;
    // Move all the parts to the right node based on t_node_id
    new0 := DISTRIBUTE(rowParts + colParts + baseParts, t_node_id);
    // Group by t_part_id and wi_id to combine all the terms
    new1 := GROUP(SORT(new0, t_part_id, wi_id, LOCAL), t_part_id, wi_id, LOCAL);
    // Combine the terms, subtracting the row part * col_parts from the base
    new2 := ROLLUP(new1, GROUP, update(ROWS(LEFT)));
    //newSub := SORTED(PROJECT(new1, Layout_Part), t_part_id, wi_id);
    // Convert from targets back to partitions
    newSub := PROJECT(new2, Layout_Part);
    // Output all four pieces sorted.  Everything can stay on the same nodes for next round.
    // Everything will be eliminated by the LOOP condition on the next time through, except
    // the sub-matrix.
    rslt1 := newCorner + newRow + newCol + newSub;
    rslt := SORT(rslt1, partition_id, wi_id, LOCAL);
    RETURN rslt;
  END; // loop Body
  
  // Get the dimensions of the matrix
  a_dims := MatDims.FromCells(A);
  // Caclulate partition dimensions
  a_part_dims := MatDims.PartitionedFromDimsForOp(OpType.square, a_dims);
  // Convert from cells to partititons
  a_parts := int.Converted.FromCells(a_part_dims, A);
  // Make sure we are in sorted order on each node
  a_sorted := SORT(a_parts, partition_id, wi_id, LOCAL);
  max_row_blocks := MAX(a_parts, a_parts.row_blocks);
  max_col_blocks := MAX(a_parts, a_parts.col_blocks);
  factorParts := LOOP(a_sorted, MIN(max_row_blocks, max_col_blocks),
                      COUNTER<=LEFT.block_row AND COUNTER<=LEFT.block_col,
                      loopBody(ROWS(LEFT), COUNTER, max_row_blocks, max_col_blocks));
 
  // Sort the results                     
  parts_rslt := SORT(factorParts, partition_id, wi_id, LOCAL);
  // Convert back to cells
  rslt := int.Converted.FromParts(parts_rslt);
  RETURN rslt;
END;