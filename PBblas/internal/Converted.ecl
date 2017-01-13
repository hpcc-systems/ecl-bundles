/*##############################################################################
## HPCC SYSTEMS software Copyright (C) 2016 HPCC Systems®.  All rights reserved.
############################################################################## */
/** 
  * Module:  Converted
  *
  * Utility module to convert matrixes between Cell-based form and Partition-based form
  * Cell based matrixes provide a (potentially) sparse form organized as 
  * DATASET(Layout_Cell).
  * Partition based matrixes are organized as a set of partitions (DATASET(Layout_Part)),
  * with each partition holding a part of the matrix (in dense form).
  * Both forms allow the matrix to be distributed among nodes so that it can be larger
  * than the memory on any one node.
  * This module provides a FromCells method as well as a FromParts method.
  */
IMPORT $.^ as PBblas;
IMPORT PBblas.Types;
IMPORT $ as int;
IMPORT int.Types as iTypes;
IMPORT Std.system.Thorlib;
partition_t := Types.partition_t;
dimension_t := Types.dimension_t;
node_t      := iTypes.node_t;
m_label_t   := Types.m_label_t;
Layout_Part := iTypes.Layout_Part;
Layout_Cell := Types.Layout_Cell;
Layout_Dims := iTypes.Layout_Dims;

EXPORT Converted := MODULE

  SHARED Work1 := RECORD(Types.Layout_Cell)
  	partition_t  partition_id;
  	node_t		 node_id;
  	dimension_t  m_rows;
  	dimension_t  m_cols;
  	dimension_t  row_blocks;
  	dimension_t  col_blocks;
  	dimension_t  block_rows;
  	dimension_t  block_cols;
  	dimension_t  block_row;
  	dimension_t  block_col;
  	m_label_t    m_label;
  END;

  /**
    * Convert a matrix in cell-based form (i.e. DATASET(Layout_Cell)) to a partition-based
    * form (i.e. DATASET(Layout_Part).  Partition sizes will be automatically determined.
    * See PBblas/Internal/MatDims.
    * Note that the cell-based form may be sparse (i.e. contains only non-zero cells).
    * The resulting partition-based matrix will contain zero in any cell not specified.
    * Partitions will no non-zero cells will be omitted.
    *
    * This module supports the "myriad" style interface in that both dimension
    * and matrix parameters may describe many separate matrices with different
    * work item ids.
    *
    * @param dims    A DATASET(Layout_Dims) of partitioned dimensions
    * @param cells   A DATASET(Layout_Cell) containing the cells of the matrix
    * @return        DATASET(Layout_Part) -- A dataset of partitions describing
    *                the same matrix(es) as the input cells.
    * @see PBblas/Types.Layout_Cell
    * @see PBblas/internal/Types.Layout_Part
    * @see PBblas/internal/Types.Layout_Dims
    */
  EXPORT DATASET(Layout_Part) FromCells(DATASET(Layout_Dims) dims, DATASET(Layout_Cell) cells,
  					BOOLEAN transpose=FALSE) := FUNCTION
    nodes := Thorlib.nodes();
    Work1 cvt_2_xcell(Layout_Cell l, Layout_Dims r) := TRANSFORM
      x := IF(transpose, l.y, l.x);
      y := IF(transpose, l.x, l.y);
      block_row           := (x-1) DIV r.block_rows + 1;
      block_col           := (y-1) DIV r.block_cols + 1;
      row_blocks          := r.row_blocks;
      partition_id        := (block_col-1) * row_blocks + block_row;
      SELF.wi_id          := l.wi_id;      
      SELF.partition_id   := partition_id;
      SELF.node_id        := (HASH32(SELF.wi_id) + partition_id-1) % nodes;
      SELF.m_rows         := r.m_rows;
      SELF.m_cols         := r.m_cols;
      SELF.row_blocks     := r.row_blocks;
      SELF.col_blocks     := r.col_blocks;
      SELF.block_rows     := r.block_rows; // Number of rows in a partition
      SELF.block_cols     := r.block_cols; // Number of cols in a partition
      SELF.block_row      := block_row; // The row num of this cells block
      SELF.block_col      := block_col; // The col num of this cells block
      SELF.m_label        := r.m_label;
      SELF := l;
    END;

    Layout_Part roll_cells(Work1 parent, DATASET(Work1) cells) := TRANSFORM
      //first_row     := mat_map.first_row(parent.partition_id);
      first_row     := (parent.block_row - 1) * parent.block_rows + 1;
      //first_col     := mat_map.first_col(parent.partition_id);
      first_col     := (parent.block_col - 1) * parent.block_cols + 1;
      part_rows     := MIN(parent.block_rows, parent.m_rows - first_row+1);
      //part_rows     := mat_map.part_rows(parent.partition_id);
      part_cols     := MIN(parent.block_cols, parent.m_cols - first_col+1);
      //part_cols     := mat_map.part_cols(parent.partition_id);
      SELF.mat_part := int.MakeR8Set(part_rows, part_cols, first_row, first_col,
                                        PROJECT(cells, Layout_Cell),
                                        transpose);
      partition_id:= parent.partition_id;
      SELF.wi_id := parent.wi_id;
      SELF.partition_id := partition_id;
      SELF.node_id     := parent.node_id;
      SELF.m_rows      := parent.m_rows;
      SELF.m_cols      := parent.m_cols;
      SELF.row_blocks  := parent.row_blocks;
      SELF.col_blocks  := parent.col_blocks;
      SELF.block_row   := parent.block_row;
      SELF.block_col   := parent.block_col;
      SELF.first_row   := first_row;
      SELF.first_col   := first_col;
      SELF.part_rows   := part_rows;
      SELF.part_cols   := part_cols;
      SELF.m_label     := parent.m_label;
      SELF := [];
    END;

    d0 := JOIN(cells, dims, LEFT.wi_id = RIGHT.wi_id, cvt_2_xcell(LEFT, RIGHT),
               LOOKUP)  : ONWARNING(4531, IGNORE);
    d1 := DISTRIBUTE(d0, node_id);
    d2 := SORT(d1, partition_id, wi_id, LOCAL);
    d3 := GROUP(d2, partition_id, wi_id, LOCAL);
    DATASET(Layout_Part) rslt := ROLLUP(d3, GROUP, roll_cells(LEFT, ROWS(LEFT)));
    RETURN rslt;
  END;
  
  /**
    * Convert a matrix in Partition-based form (i.e. DATASET(Layout_Part))
    * to Cell-based form (i.e. DATASET(Layout_Cell)).
    * Note that the returned cell-based matrix is sparse, in that it will only 
    * contain rows for cells that were non-zero in the original matrix.
    *
    * This interface supports "myriad" style, in that the partitions may 
    * represent many independent matrixes separated by different work item ids.
    * 
    * @param parts_recs     A DATASET(Layout_Parts) specifying the matrix(es) to
    *                       be converted
    * @param transpose      BOOLEAN parameter causes each matrix to be transposed
    *                       during conversion
    * @see Std/PBblas/Types.Layout_Cell
    * @see Std/PBblas/Types.Layout_Part
    */
  EXPORT FromParts(DATASET(Layout_Part) part_recs, BOOLEAN transpose=FALSE) := FUNCTION
    // Convert from dense to sparse
    Layout_Cell cvtPart2Cell(Layout_Part pr, UNSIGNED4 c) := TRANSFORM
      row_in_block := ((c-1)  %  pr.part_rows) + 1;
      col_in_block := ((c-1) DIV pr.part_rows) + 1;
      v := pr.mat_part[c];
      SELF.wi_id := pr.wi_id;
      SELF.v  := IF(v = 0.0, SKIP, v);
      x  := pr.first_row + row_in_block - 1;
      y  := pr.first_col + col_in_block - 1;
      SELF.x := IF(transpose, y, x);
      SELF.y := IF(transpose, x, y);
    END;
    DATASET(Layout_Cell) result := NORMALIZE(part_recs, COUNT(LEFT.mat_part), cvtPart2Cell(LEFT, COUNTER));
    return result;
  END;
END;