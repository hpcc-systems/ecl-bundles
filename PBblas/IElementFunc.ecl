/*##############################################################################
## HPCC SYSTEMS software Copyright (C) 2016 HPCC Systems®.  All rights reserved.
############################################################################## */

IMPORT $ as PBBlas;
value_t := PBblas.Types.value_t;
dimension_t := PBblas.Types.dimension_t;

/**
  * Function prototype for a function to apply to each element of the 
  * distributed matrix
  *
  * Base your function on this prototype:
  * 
  * @param v   Input value
  * @param r   Row number (1 based)
  * @param c   Column number (1 based)
  * @return    Output value
  * @see       PBblas/Apply2Elements
  */
EXPORT value_t IElementFunc(value_t v, dimension_t r, dimension_t c) := v;
