/*##############################################################################
## HPCC SYSTEMS software Copyright (C) 2016 HPCC Systems®.  All rights reserved.
############################################################################## */

IMPORT $.^ as PBblas;
IMPORT PBblas.internal as int;
IMPORT PBblas.Types;
IMPORT int.Types as iTypes;


max_block := 1000000;

test_rec := {UNSIGNED N, UNSIGNED M, UNSIGNED P};
UNSIGNED nodes := 1;
node_counts := DATASET([
  {1},
  {3},
  {21},
  {101}
  ], {UNSIGNED node_count});
  
// Test cases consist of a series of N, M, and P corresponding to the dimensions of matrixes A (N x M), B(M x P), 
// and C(N x P)
// 
test_cases := DATASET([
  // {N, M, K}
  {10000000, 2000, 2000},
  {10000, 10000, 10000},
  {100,1000,100},
  {500000,15, 20},
  {15,500000,20},
  {20000000,1000, 100},
  {15, 20, 5000000},
  {3000000,100000, 10},
  {3000000, 100000, 100000},
  {100000000, 1000,100000},
  {5000000, 3, 3},
  {5000000, 100000, 3},
  {5000000, 3, 100000},
  {3,3,3},
  {10, 5, 10},
  {500,3,2},
  {3, 3, 0},
  {3, 0, 3},
  {0, 3, 3},
  {0, 0, 0},
  {500, 3, 2},
  {5, 500, 5},
  {100000, 398348, 4956992}, // Worst case test for roundoff
  {4147829, 13000, 25054}  // Worst case test for wasted space due to roundoff compensation
  ],test_rec);

ext_test_rec := RECORD(test_rec)
  UNSIGNED nodes;
END;

DATASET(ext_test_rec) extend_test_cases(test_rec l, {UNSIGNED node_count} r) := TRANSFORM
  SELF.nodes := r.node_count;
  SELF := l;
END;

DATASET(ext_test_rec) test_cases_ext := JOIN(test_cases, node_counts, TRUE, extend_test_cases(LEFT, RIGHT), ALL);
result_rec := {
  UNSIGNED nodes,
  UNSIGNED N,
  UNSIGNED M,
  UNSIGNED P, 
  UNSIGNED PN,
  UNSIGNED PM,
  UNSIGNED PP,
  STRING6 partition_type,
  UNSIGNED a_block_rows, 
  UNSIGNED a_block_cols,
  UNSIGNED b_block_cols, UNSIGNED a_block_size, 
  UNSIGNED b_block_size, UNSIGNED c_block_size, 
  UNSIGNED a_parts,
  UNSIGNED b_parts,
  UNSIGNED c_parts, 
  UNSIGNED partitions,
  UNSIGNED berror,
  STRING error_text,
  String status};

result_rec do_tests(ext_test_rec r) := TRANSFORM
  b := int.BlockDimensionsMultiply(r.N, r.M, r.P, max_block, r.nodes);
  SELF.nodes := r.nodes;
  SELF.N := r.N;
  SELF.M := r.M;
  SELF.P := r.P;
  SELF.PN := b.PN;
  SELF.PM := b.PM;
  SELF.PP := b.PP;
  SELF.a_block_rows := b.AblockRows;
  SELF.a_block_cols := b.AblockCols;
  SELF.b_block_cols := b.BblockCols;
  SELF.a_parts := SELF.PN * SELF.PM;
  SELF.b_parts := SELF.PM * SELF.PP;
  SELF.c_parts := SELF.PN * SELF.PP;
  SELF.partitions := SELF.a_parts + SELF.b_parts + SELF.c_parts;
  SELF.a_block_size := SELF.a_block_rows * SELF.a_block_cols;
  SELF.b_block_size := SELF.a_block_cols * SELF.b_block_cols;
  SELF.c_block_size := SELF.a_block_rows * SELF.b_block_cols;
  SELF.partition_type := iTypes.PartitionTypeString(b.Partitioning);
  SELF.berror := IF(SELF.PN = 0 or SELF.PM = 0 or SELF.PP = 0, 5,
    IF(SELF.a_block_size > max_block OR SELF.b_block_size > max_block OR SELF.c_block_size > max_block, 4,
      IF(SELF.PN > SELF.N OR SELF.PM > SELF.M OR SELF.PP > SELF.P, 3,
        IF(SELF.a_parts % SELF.nodes != 0 OR SELF.b_parts % SELF.nodes != 0 OR SELF.c_parts % SELF.nodes != 0, 2, 
          IF(SELF.a_block_size < 1 OR SELF.b_block_size < 1 OR SELF.c_block_size < 1, 1, 0)))));
  SELF.error_text := CASE(SELF.berror, 0 => 'None', 5 => 'Partition has zero dimension', 4 => 'Partition size too large', 3 => 'Partition size > cells',
    2 => 'Couldn\'t use all nodes', 1 => 'Partition size too small', 'Unknown');
  SELF.status := IF(self.berror > 3, 'FAIL', 'SUCCESS');
END;

DATASET(result_rec) result_data := PROJECT(test_cases_ext, do_tests(LEFT));

/**
  * Test driver for Std.PBblas.BlockDimensionsMultiply
  *
  * Also indirectly exercises all aspects of Std.PBblas.BlockDimensions.
  *
  * Test against many different values of N, M, and P.  Verify that
  * the hierarchical constraints are met.
  * @see Std/PBblas/BlockDimensionsMultiply
  * @see Std/PBblas/BlockDimensions
  */
EXPORT BlockDimensionsMultiply := result_data;

// Note that BlockDimensions attempts to choose the best partition matrixes that meet four prioritized constraints 
// (see Std.PBblas.BlockDimensions).
// For any given N, M, and P, it may not be possible to meet all four constraints.  Therefore 'error' may not always 
// be zero.
// Error can take one of the following values:
// 5:  Zero block dimension -- one of the block dimensions is zero which is invalid
// 4:  Failed to meet constraint 1 -- maximum partition size.  This should be considered a failure and should never happen
// 3:  Failed to meet constraint 2 -- no empty partitions.  This should rarely happen and is not a failure.
// 2:  Failed to meet constraint 3 -- use all nodes.  This will commonly occur with small matrixes.
// 1:  Failed to meet constraint 4 -- minimum partition size.  This will occasionally occur.
// 0:  All constraints met -- the best case.
