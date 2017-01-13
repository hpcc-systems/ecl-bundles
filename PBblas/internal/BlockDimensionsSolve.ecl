/*##############################################################################
## HPCC SYSTEMS software Copyright (C) 2016 HPCC Systems®.  All rights reserved.
############################################################################## */
IMPORT $.^ as PBblas;
IMPORT $ as int;
IMPORT PBblas.Types;


dimension_t := Types.dimension_t;

/**
* Auto-Partitioning for Solve operations
*
* Given an input of N and M, describing the dimensions of A (N x N), B (N x M) or (M x N) 
* matrixes, calculate the optimal square (d x d) partitioning for A and rectangular
* partitioning for B.  Calculate the partition matrix dimensions: PN and PM representing the
* dimensions of the partition
* matrixes for A and B respectively (P(A): PN x PN, P(B): PM x PN or PN x PM.
* Note that for solving Ax=B, B will be N x M, and for solving xA = B, B will be M x N.
* Each of the partition matrixes is subject to the following constraints:
* 1) Cells per partition <= 1,000,000
* 2) Partitions should not be empty:  At least one row and column in each partition
* 3) The number of partitions should be a multiple of the number of nodes
* 4) Partition size as large as possible
*
* Note: These constraints are in priority order.  (1) should always be met.  Others are best effort.
* Note: This module is used internally to PBblas, and should not be needed by users of PBblas
*
* @param N		The Row and Column dimension of the A matrix and either the Row or Column 
*                dimension of B (depending on the type of solve).
* @param M		The Column or Row dimension of B (depending on the type of 
*                solve)
* @param max_part_size_or Overrides the largest allowed partition size.
*                For advanced use only.
* @param nodes_or For testing only.  Overrides the number of nodes in the cluster.
*                          Should never be used in production.
* @see			Std/PBblas/BlockDimensions
*/
EXPORT BlockDimensionsSolve(dimension_t N, dimension_t M, 
	  max_part_size_or=0, nodes_or=0) := MODULE
  // Maximum partition size to generate (allows override via STORE or via 
  // parameter for testing)
  stored_max_part_size := 1000000 : STORED('BlockDimensions_max_partition_size');
  SHARED max_part_size := IF(max_part_size_or > 0, max_part_size_or, stored_max_part_size);
  SHARED a_cells := N*N;
  SHARED b_cells := N*M;
  EXPORT min_cells := MIN(a_cells, b_cells);
  EXPORT max_cells := MAX(a_cells, b_cells);

  // Find the best square partitioning for A
  bd := int.BlockDimensions(N, N, max_part_size_or, nodes_or);
  A_block_dim := bd.PN; // PN and PM will always be the same because scheme will always be square.
  SHARED PN0 := A_block_dim;
  // Calculate PM such that B partitions are smaller than max_partition_size
  min_PM := ROUNDUP(b_cells/max_part_size/PN0);
  max_PM := ROUNDUP((b_cells+min_PM*N) / max_part_size / PN0);
	SHARED PM0 := IF((b_cells / PN0) % min_PM = 0, min_PM, max_PM);

  /**
    * The row and column dimension of A's partition matrix and either row or column of B's
    */
  EXPORT PN := PN0;
  /**
    * The row or column dimension of B and X(result) matrixes depending on the type
    * of solve (see module description).
    */
  EXPORT PM := PM0;
  /**
    * The number of rows and columns in each partition of A
    * @return  The side dimension of 'A' matrix (a is square)
    */
  EXPORT AblockDim := ROUNDUP(N/PN);
  /**
    * The number of rows or columns in each partition of B and X (result) depending
    * on the type of solve (see module description). 
    */
  EXPORT BblockDim := ROUNDUP(M/PM);
END; 