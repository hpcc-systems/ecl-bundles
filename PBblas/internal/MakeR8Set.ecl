/*##############################################################################
## HPCC SYSTEMS software Copyright (C) 2016 HPCC Systems®.  All rights reserved.
############################################################################## */

IMPORT $.^ as PBblas;
IMPORT PBblas.Types;
dimension_t := Types.dimension_t;
value_t := Types.value_t;
Layout_Cell := Types.Layout_Cell;

/**
  * Take a dataset of cells (or sub-matrix thereof) and pack into a dense matrix.
  * in column major order [r1c1, r2c1, r3c1, ..., rNc1, r1c2, ..., rNcM].
  * First row and first column are one based.
  *
  * @param  r         The number of rows in the matrix or sub-matrix
  * @param  s         The number of columns in the matrix or sub-matrix
  * @param first_row  The first row to include in the submatrix
  * @param first_col  The first column to include in the submatrix
  * @param D          The matrix to convert in Layout_Cell form
  * @param transpose  Boolean to transpose the matrix during conversion (optional)
  * @return           Dense matrix or sub-matrix (SET OF REAL8)
  */
EXPORT SET OF REAL8 makeR8Set(dimension_t r, dimension_t s,
                              dimension_t first_row, dimension_t first_col,
                              DATASET(Layout_Cell) D,
                              BOOLEAN transpose=FALSE) := BEGINC++
    // copy of Layout_Cell translated to C
    typedef struct __attribute__ ((__packed__)) work1 {      
      uint16_t wi_id;
      uint32_t x;
      uint32_t y;
      double v;
    };
    #body
    __lenResult = r * s * sizeof(double);
    __isAllResult = false;
    double* result = (double*) rtlMalloc(__lenResult);
    //double * result = new double[r*s];
    __result = (void*) result;
    work1 *cell = (work1*) d;
    uint32_t cells = lenD / sizeof(work1);
    uint32_t i;
    uint32_t pos;
    for (i=0; i<r*s; i++) {
      result[i] = 0.0;
    }
    int x, y;
    for (i=0; i<cells; i++) {
      x = transpose ? cell[i].y - first_row : cell[i].x - first_row;
      y = transpose ? cell[i].x - first_col : cell[i].y - first_col;
      if(x < 0 || (uint32_t) x >= r) continue;   // cell does not belong
      if(y < 0 || (uint32_t) y >= s) continue;
      pos = (y*r) + x;
      result[pos] = cell[i].v;
    }
  ENDC++;
