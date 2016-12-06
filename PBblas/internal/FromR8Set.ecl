/*##############################################################################
## HPCC SYSTEMS software Copyright (C) 2016 HPCC Systems®.  All rights reserved.
############################################################################## */
IMPORT $.^ as PBblas;
IMPORT PBblas.Types;
dimension_t := Types.dimension_t;
value_t := Types.value_t;
Layout_Cell := Types.Layout_Cell;
/**
  * Take a dense matrix or submatrix and convert it to a sparse matrix in
  * Layout_Cell format.
  *
  * @param mat_data   A set of REAL8 values representing a matrix in column
  *                   major order [r1c1, r2c1, r3c1, ..., rNc1, r1c2, ..., rNcM]
  * @param num_rows   The number of rows in the matrix
  * @param row_offset The offset to the starting row of this sub-matrix 
  *                   (optional)
  * @param col_offset The offset to starting column of this sub-matrix
  *                   (optional)
  * @return           DATASET(Layout_Cell) -- A sparse matrix.
  * @see              PBblas/Types.Layout_Cell
  */
EXPORT DATASET(Layout_Cell) FromR8Set(SET OF REAL8 mat_data,
			dimension_t num_rows,
			dimension_t row_offset=0, dimension_t col_offset=0) := FUNCTION
	dummy_rec := RECORD  // Just use dummy rec for normalize in order to iterate over
						// the set.  There must be a better way
  		STRING1 x:= '';
	END;
	temp := DATASET([{' '}], dummy_rec);
	Layout_Cell cvtData2Cell(UNSIGNED c) := TRANSFORM
		m_value := mat_data[c];
     	SELF.v  := IF(m_value = 0.0, SKIP, m_value);
    	row_in_block := ((c-1)  %  num_rows) + 1;
    	col_in_block := ((c-1) DIV num_rows) + 1;
    	SELF.x := row_offset + row_in_block;
    	SELF.y := col_offset + col_in_block;
  	END;

		
    DATASET(Layout_Cell) rslt := NORMALIZE(temp, COUNT(mat_data), cvtData2Cell(COUNTER));
    return rslt;
END;
