/*##############################################################################
## HPCC SYSTEMS software Copyright (C) 2016 HPCC Systems®.  All rights reserved.
##############################################################################*/

IMPORT $ as PBblas;
IMPORT PBblas.Types;
IMPORT PBblas.internal as int;
IMPORT int.Types as iTypes;
IMPORT int.MatDims;

dimension_t  := Types.dimension_t;
value_t      := Types.value_t;
Layout_Cell  := Types.Layout_Cell;
Layout_Dims  := iTypes.Layout_Dims;
Layout_WI_ID := iTypes.Layout_WI_ID;
work_item_t  := Types.work_item_t;

/**
  * Provides various utility attributes for manipulating cell-based matrixes
  * @see Std/PBblas/Types.Layout_Cell
  */
EXPORT MatUtils := MODULE
  W_Rec := RECORD
    STRING1 x:= '';
  END;
  W0 := DATASET([{' '}], W_Rec);
  /**
    * Get a list of work-item ids from a matrix containing one or more work items
    *
    * @param cells     A matrix in Layout_Cell format
    * @return          DATASET(Layout_WI_ID), one record per work-item
    * @see			   PBblas/Types.Layout_Cell
    * @see			   PBblas/Types.Layout_WI_ID
    */
  EXPORT DATASET(Layout_WI_ID) GetWorkItems(DATASET(Layout_Cell) cells) := FUNCTION
    wi_list := RECORD
      work_item_t wi_id := cells.wi_id;
    END;
    wi_list work_items := TABLE(cells, wi_list, wi_id, FEW, UNSORTED);
    result := PROJECT(work_items, Layout_WI_ID); 
    return result;
  END;
  /**
    * Insert one or more columns of a fixed value into a matrix.
    * Columns are inserted before the first original column.
    *
    * This attribute supports the myriad interface.  Multiple independent matrixes
    * can be represented by M.
    *
    * @param M              the input matrix
    * @param cols_to_insert the number of columns to insert, default 1
    * @param insert_val     the value for each cell of the new column(s),     
    *                       default 0
    * @return               matrix in Layout_Cell format with additional column(s)
    * 
    */
  EXPORT DATASET(Layout_Cell) InsertCols(DATASET(Layout_Cell) M, UNSIGNED cols_to_insert=1, 
    value_t insert_val=1) := FUNCTION
    Layout_Cell cvt(Layout_Cell cell) := TRANSFORM
    	SELF.y := cell.y + cols_to_insert;
    	SELF := cell;
    END;
    Layout_Cell make_cells(UNSIGNED c, Layout_Dims l) := TRANSFORM
        m_rows := l.m_rows;
        valid := c <= m_rows*cols_to_insert;
    	x := IF(valid, (c-1) % m_rows + 1, SKIP);
    	y := (c-1) DIV m_rows + 1;
    	SELF.wi_id := l.wi_id;
    	SELF.x := x;
    	SELF.y := y;
    	SELF.v := insert_val;
    END;
    // Get the dimensions of the input matrix(es)
    dims1 := MatDims.FromCells(M);
    maxDim := MAX(dims1, m_rows);
    dims := DISTRIBUTE(dims1, wi_id);
    
    // Create a column of cells for each work-item.  Distribute those cells across nodes.
    DATASET(Layout_Cell) new_cells := NORMALIZE(dims, cols_to_insert*maxDim, make_cells(COUNTER, LEFT));
    // Adjust the column number for all existing cells;
    DATASET(Layout_Cell) adj_cells := PROJECT(M, cvt(LEFT));
    // Return the adjusted cells and the new cells concatenated together
    rslt := adj_cells + new_cells;
    return rslt;
  END;
  /**
    * Transpose a matrix
    * 
    * This attribute supports the myriad interface.  Multiple independent matrixes
    * can be represented by M.
    *
    * @param M  A matrix represented as DATASET(Layout_Cell)
    * @return   Transposed matrix in Layout_Cell format
    * @see      PBblas/Types.Layout_Cell
    */
  EXPORT DATASET(Layout_Cell) Transpose(DATASET(Layout_Cell) M) := FUNCTION
    Layout_Cell trans(Layout_Cell lr) := TRANSFORM
      SELF.x := lr.y;
      SELF.y := lr.x;
      SELF   := lr;
    END;
    rslt := PROJECT(M, trans(LEFT));
    return rslt;
  END;

END;