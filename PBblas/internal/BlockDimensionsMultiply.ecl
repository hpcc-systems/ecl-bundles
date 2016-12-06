/*##############################################################################
## HPCC SYSTEMS software Copyright (C) 2016 HPCC Systems®.  All rights reserved.
############################################################################## */
IMPORT $.^ as PBblas;
IMPORT $ as int;
IMPORT PBblas.Types;
IMPORT int.Types as iTypes;


dimension_t := Types.dimension_t;

/**
* Auto-Partitioning for Multiply operations
*
* Given an input of N, M, and P, describing the dimensions of A (N x M), B (M x P), and C (N x P) 
* matrixes, calculate the optimal square (d x d), row (d x 1), or column (1 x d) partition  
* matrix dimensions: PN, PM, and PP, representing the dimensions of the three partition
* matrixes for A, B, and C respectively (P(A): PN x PM, P(B): PM x PP, P(C): PN x PP). 
* Each of the partition matrixes is subject to the following constraints:
* 1) Cells per partition <= 1,000,000
* 2) Partitions should not be empty:  At least one row and column in each partition
* 3) The number of partitions should be a multiple of the number of nodes
* 4) Partition size as large as possible
*
* Note: These constraints are in priority order.  (1) should always be met.  Others are best effort.
* Note: This module is used internally to PBblas, and should not be needed by users of PBblas
*
* @param N		The Row dimension of the A matrix (multiplier) and the C (addend) and Result matrixes
* @param M		The Column dimension of the A matrix and the Row dimension of the B matrix (multiplicand)
* @param P		The Column dimension of the B matrix and of the C and Result matrixes
* @param max_part_size_or Overrides the largest allowed partition size.  For advanced use only.
* @param nodes_or For testing only.  Overrides the number of nodes in the cluster.
*                          Should never be used in production.
* @see			Std/PBblas/BlockDimensions
*/
EXPORT BlockDimensionsMultiply(dimension_t N, dimension_t M, dimension_t P, 
	  max_part_size_or=0, nodes_or=0) := MODULE
  // Maximum partition size to generate (allows override via STORE or via 
  // parameter for testing)
  stored_max_part_size := 1000000 : STORED('BlockDimensions_max_partition_size');
  SHARED max_part_size := IF(max_part_size_or > 0, max_part_size_or, stored_max_part_size);
  SHARED a_cells := N*M;
  SHARED b_cells := M*P;
  SHARED c_cells := N*P;
  EXPORT min_cells := MIN([a_cells, b_cells, c_cells]);
  EXPORT max_cells := MAX([a_cells, b_cells, c_cells]);

  SHARED SET OF dimension_t A_first := FUNCTION
    // A is the largest matrix.  Optimize that first.
    bd := int.BlockDimensions(N, M, max_part_size_or, nodes_or);
    row_blocks := bd.PN;
    col_blocks := bd.PM;
    PN := row_blocks;
    PM := col_blocks;
    // Calculate PP such that both B and C matrixes have partition sizes smaller than max_partition_size
    min_PP := ROUNDUP(MAX([b_cells/max_part_size/PM, c_cells/max_part_size/PN, 1]));
    max_PP := ROUNDUP(MAX([(b_cells+min_PP*M) / max_part_size / PM, (c_cells+min_PP*N) / max_part_size / PN,1]));
	PP := IF((b_cells / PM) % min_PP = 0 AND (c_cells / PN) % min_PP = 0, min_PP, max_PP);
    results := [PN, PM, PP];
    return results;
  END;
  SHARED SET OF dimension_t B_first := FUNCTION
    // B is the largest matrix.  Optimize that first.
    bd := int.BlockDimensions(M, P, max_part_size_or, nodes_or);
    row_blocks := bd.PN;
    col_blocks := bd.PM;
    PM := row_blocks;
    PP := col_blocks;
    // Calculate PN such that both A and C matrixes have partition sizes smaller than max_partition_size
    min_PN := ROUNDUP(MAX([a_cells/max_part_size/PM, c_cells/max_part_size/PP], 1));
    max_PN := ROUNDUP(MAX([(a_cells+min_PN*M) / max_part_size / PM, (c_cells + min_PN*P) / max_part_size / PP,1]));
	PN := IF((a_cells / PM) % min_PN = 0 AND (b_cells / PP) % min_PN = 0, min_PN, max_PN);
    results := [PN, PM, PP];
    return results;
  END;
  SHARED SET OF dimension_t C_first := FUNCTION
    // C is the largest matrix.  Optimize that first.
    bd := int.BlockDimensions(N, P, max_part_size_or, nodes_or);
    row_blocks := bd.PN;
    col_blocks := bd.PM;
    PN := row_blocks;
    PP := col_blocks;
    // Calculate PM such that both A and B matrixes have partition sizes smaller than max_partition_size
    min_PM := ROUNDUP(MAX([a_cells/max_part_size/PN, b_cells/max_part_size/PP,1]));
    max_PM := ROUNDUP(MAX([(a_cells + min_PM*N) / max_part_size/ PN, (b_cells + min_PM*P) / max_part_size / PP,1]));
	PM := IF((a_cells / PN) % min_PM = 0 AND (b_cells / PP) % min_PM = 0, min_PM, max_PM);
    results := [PN, PM, PP];
    return results;
  END;

  // Start with the largest matrix and work from there
  SHARED solution := IF(a_cells = max_cells, A_first, 
    IF(b_cells = max_cells, B_first, C_first));
  /**
    * The row dimension of A's partition matrix and of the C and result partition matrixes
    */
  EXPORT PN := solution[1];
  /**
    * The column dimension of A's partition matrix and the row dimension of B's partition matrix
    */
  EXPORT PM := solution[2];
  /**
    * The column dimension of B's partition matrix and of the C and result partition matrixes
    */
  EXPORT PP := solution[3];
  /**
    * The number of rows in each partition of A, C and result matrixes
    */
  EXPORT AblockRows := ROUNDUP(N/PN);
  /**
    * The number of columns in each partition of A, and the number of rows in each partition of B matrix
    */
  EXPORT AblockCols := ROUNDUP(M/PM);
  /**
    * The number of columns in each partition of B, C, and result matrixes
    */
  EXPORT BblockCols := ROUNDUP(P/PP);
  /**
    * The type of partitioning used. See Types.PartitionType
    *
    * @see Std/PBblas/Types.ecl
    */
  EXPORT iTypes.PartitionType Partitioning := int.BlockDimensions(N, M, max_part_size_or, nodes_or).Partitioning;
END; 