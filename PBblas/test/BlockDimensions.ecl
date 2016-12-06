/*##############################################################################
## HPCC SYSTEMS software Copyright (C) 2016 HPCC Systems®.  All rights reserved.
############################################################################## */

/**
  * Test program for BlockDimensions
  *
  */
  
IMPORT $.^ as PBblas;
IMPORT PBblas.internal as int;
IMPORT int.MatDims;
IMPORT PBblas.Types;
IMPORT int.Types as iTypes;
IMPORT $ as Tests;
IMPORT Tests.MakeTestMatrix as tm;
OpType        := iTypes.OpType;
dimension_t   := Types.dimension_t;
PartitionType := iTypes.PartitionType;

tc_record := RECORD
  dimension_t N;
  dimension_t M;
END;
test_cases := DATASET([{5, 5},
                {10,10},
                {40,40},
                {1000, 100},
                {10000, 5},
                {5, 10000},
                {41, 39},
                {9,10},
                {31, 31},
                {32, 32}
                ], tc_record);

result_rec := RECORD
  dimension_t N;
  dimension_t M;
  dimension_t PN;
  dimension_T PM;
  dimension_t BlockRows;
  dimension_t BlockCols;
  dimension_t BlockSize;
  UNSIGNED error_type;
  UNSIGNED failed;
END;

max_partition_size := 1000;
override := #STORED('BlockDimensions_max_partition_size', max_partition_size);

result_rec do_test(tc_record tc) := TRANSFORM
  N := tc.N;
  M := tc.M;
  dims := int.BlockDimensions(N, M);
  PN := dims.PN;
  PM := dims.PM;
  partitioning := dims.Partitioning;
  cells := N * M;
  block_rows := dims.BlockRows;
  block_cols := dims.BlockCols;
  block_size := block_rows * block_cols;
  SELF.PN := PN;
  SELF.PM := PM;
  SELF.BlockRows := block_rows;
  SELF.BlockCols := block_cols;
  SELF.BlockSize := block_size;
  // Error Types:
  // 0 : No Error
  // 1 : Non square partitioning for square matrix
  // 2 : Partition size too big
  // 3 : Partition size too small
  SELF.error_type := IF(N = M AND (PN != PM OR (PN > 1 AND partitioning != PartitionType.square)), 1,
                       IF(block_size > 1000, 2,
                         IF(block_size < 100 AND cells > 100, 3, 0)));
  SELF.failed := IF(SELF.error_type > 0, 1, 0);
  SELF := tc;
END;

rslt := PROJECT(test_cases, do_test(LEFT));

EXPORT BlockDimensions := WHEN(rslt, override);