/*##############################################################################
## HPCC SYSTEMS software Copyright (C) 2016 HPCC Systems®.  All rights reserved.
############################################################################## */
// Constants used in PB BLAS
EXPORT Constants := MODULE
  EXPORT Block_Minimum := 100000;   // minimum cells in a block
  EXPORT Block_NoSplit := 200000;   // minimum to split into blocks
  EXPORT Block_Maximum := 10000000; // Maximum cells in a block
  EXPORT Block_Vec_Rows:= 10000;    // Standard rows for a column vector of blocks

  // Message strings and Codes
  SHARED Error_Base         := 70000;
  EXPORT Dimension_Incompat := 'Matrix dimensions are incompatible';
  EXPORT Dimension_IncompatZ:= Error_Base + 1;
  EXPORT Distribution_Error := 'Matrix not distributed correctly';
  EXPORT Distribution_ErrorZ:= Error_Base + 2;
  EXPORT Not_Square         := 'Matrix is not square';
  EXPORT Not_SquareZ        := Error_Base + 3;
  EXPORT Not_PositiveDef    := 'Not a positive-definite full rank matrix';
  EXPORT Not_PositiveDefZ   := Error_Base + 4;
  EXPORT Not_Single_Block   := 'Matrix is not a single block';
  EXPORT Not_Single_BlockZ  := Error_Base + 5;
  EXPORT Not_Block_Vector   := 'Matrix not a block vector';
  EXPORT Not_Block_VectorZ  := Error_Base + 6;
END;