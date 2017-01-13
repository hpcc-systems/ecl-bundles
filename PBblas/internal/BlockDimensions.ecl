/*##############################################################################
## HPCC SYSTEMS software Copyright (C) 2016 HPCC Systems®.  All rights reserved.
############################################################################## */

IMPORT $.^ as PBblas;
IMPORT PBblas.Types;
IMPORT $ as int;
IMPORT int.Types as iTypes;
IMPORT Std.system.Thorlib;

dimension_t := Types.dimension_t;
p_types := iTypes.PartitionType;


/**
  * Auto-Partitioning for a Single Matrix
  *
  * Given an input of N and M describing the dimensions of a matrix (N rows x M columns),
  * calculate the optimal square (d x d), row (d x 1), or column (1 x d) partition  
  * matrix dimensions: PN and BM,  subject to the following constraints:
  * 1) Cells per partition <= 1,000,000
  * 2) Partitions should not be empty:  At least one row and column in each partition
  * 3) The number of partitions should be a multiple of the number of nodes
  * 4) Partition size as large as possible
  *
  * Note: These constraints are in priority order.  (1) should always be met.  Others are best effort.
  * Note: This module is used internally to PBblas, and should not be needed by users of PBblas
  *
  * @param N		The row dimension of the matrix to be partitioned
  * @param M		The column dimension of the matrix to be partitioned
  * @param max_partition_size The largest allowed partition size.  For advanced use only.
  * @param nodes_override For testing only.  Overrides the number of nodes in the cluster.
  *                          Should never be used in production.
  */


EXPORT BlockDimensions(dimension_t N, dimension_t M,  
  max_partition_size_or=0, nodes_override=0) := MODULE
  // Maximum partition size to generate (allows override via STORE or param for testing)
  max_partition_size_stored := 1000000 : STORED('BlockDimensions_max_partition_size');
  SHARED max_partition_size := IF(max_partition_size_or > 0, max_partition_size_or, 
  									max_partition_size_stored);
  // Cluster size (allows override via STORE or param for testing)
  nodes_stored := Thorlib.nodes() : STORED('BlockDimensions_nodes');
  SHARED nodes := IF(nodes_override > 0, nodes_override, nodes_stored);
  // Partition size below which to use a single partition (allows override via STORE for testing)
  SHARED single_partition_size := 100 : STORED('BlockDimensions_single_partition_size');
  // Function to round up a dimension to the nearest number of nodes
  SHARED dimension_t round_up_to_nodes(dimension_t d) := FUNCTION
    dimension_t rounded := IF(d % nodes > 0, d  + (nodes - d % nodes), d);
    return rounded; 
  END;

  SHARED cells := N * M; // Total number of cells in matrix
  SHARED is_square := N = M; // Need special handling for exactly square matrix
  SHARED min_rc := MIN([N, M]); // The smallest dimension of N or M
  SHARED max_rc := MAX([N,M]); // The largest dimension of N or M
  min_D :=  ROUNDUP(SQRT(cells / max_partition_size)); // Constraint 1
  max_D := min_rc; // Constraint 2
  // Unless min_D happens to be an even divisor of both N and M, we need to
  // adjust it so that each partition will still be less than max_partition_size
  // when we round up the row and column count of the partition.
  // This is a complicated adjustment that is explained more fully in Jira ML-290.
  // Maximum error ratio -- compensates for two iterations (see ML-290 for explanation)
  mer := (M*N + min_D*N + min_D*M) / (M*N);
  temp_D := __COMMON__(IF(N % min_D = 0 AND M % min_D = 0, min_D, 
    ROUNDUP(SQRT((cells + min_D*mer*(M + N)) / max_partition_size))));
  temp_D1 := round_up_to_nodes(temp_D); // Constraint 3
  // If the round up results in tiny partitions, just use the original.  This is
  // because the round up can dwarf the original calc (e.g. if temp_D is 2 and nodes is
  // 100).
  temp_D2 := __COMMON__(IF(cells / (temp_D1 * temp_D1) < single_partition_size, temp_D, temp_D1));
  // Special case for square matrixes.  Should always use square partitioning,
  // even if not all nodes are used.
  // Note:  if temp_D1 > max_D, square partitioning will fail and will
  //  resort to row or column.  Thus, with the exception of the special-case
  //  above, we will enforce Constraint 3 unless it conflicts with C2.
  SHARED dimension_t test_D := IF(temp_D2 > max_D AND is_square, max_D, temp_D2);
  
  // Internal function to calculate a vector block size within a specified limit
  SHARED dimension_t calc_vector_block_size(dimension_t dlimit) := FUNCTION
  	min_partitions := ROUNDUP(cells / max_partition_size);
  	other_dim := cells / dlimit;
    temp_bsize := IF(min_partitions % dlimit = 0, min_partitions, ROUNDUP((cells + other_dim*min_partitions)/max_partition_size));
    test_bsize := round_up_to_nodes(temp_bsize);
    dimension_t bsize := IF(test_bsize <= dlimit, test_bsize, dlimit);
    return bsize;
  END;
  /**
    * The type of partitioning employed: Types.PartitionType.square, .row, or .column or .single
    */
  //EXPORT Partitioning := IF(cells < single_partition_size, p_types.single,
  //  IF(test_D = 1, p_types.single, IF(test_D <= min_rc, p_types.square, IF(N < M, p_types.column, p_types.row))));
  EXPORT Partitioning := MAP(cells < single_partition_size => p_types.single,
                             test_D = 1                    => p_types.single,
                             test_D <= min_rc              => p_types.square,
                             N < M                         => p_types.column,
                                                              p_types.row);
  /**
    * The row dimension of the optimal Partition Matrix
    */
  EXPORT dimension_t PN := __COMMON__(CASE(Partitioning, p_types.column => 1, 
    p_types.row => calc_vector_block_size(N), p_types.square => test_D, 1));
  /**
    * The column dimension of the optimal Partition Matrix
    */
  EXPORT dimension_t PM := __COMMON__(CASE(Partitioning, p_types.column => calc_vector_block_size(M), 
    p_types.row => 1, p_types.square => test_D, 1));	
  /**
    * The number of rows in each partition (i.e. block)
    */
  EXPORT BlockRows := ROUNDUP(N/PN);
  /**
    * The number of columns in each partition (i.e. block)
    */
  EXPORT BlockCols := ROUNDUP(M/PM);
END; 