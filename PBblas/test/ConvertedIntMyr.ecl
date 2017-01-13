/*##############################################################################
## HPCC SYSTEMS software Copyright (C) 2016 HPCC Systems®.  All rights reserved.
############################################################################## */
/**
  * Myriad Test for PBblas/internal/Converted.ecl module
  * Converts from cells to partitions, and then back to cells
  * using Converted.FromCells and Converted.FromParts.
  *
  */
IMPORT Std.System.Thorlib;
IMPORT $.^ as PBblas;
IMPORT PBblas.internal as int;
IMPORT PBblas.Types;
IMPORT int.Types as iTypes;
IMPORT PBblas.MatUtils;
IMPORT int.MatDims;

IMPORT $ as Tests;
IMPORT Tests.MakeTestMatrix as tm;

// Override max_partition_size so that we can test partitioned with smaller data
max_partition_size := 1000;
override := #STORED('BlockDimensions_max_partition_size', max_partition_size);

Layout_Cell := Types.Layout_Cell;
Layout_Part := iTypes.Layout_Part;
nodes := Thorlib.nodes();
// Test configuration Parameters -- modify these to vary the testing
N := 500;   // Number of rows
M := 500;      // Number of columns

density := 1.0; // 1.0 is fully dense. 0.0 is empty.
// End of config parameters

// Generate cell-based Matrix to test with
cells1 := tm.Matrix(N, M, density); // wu_id = 1 (default)
cells2 := tm.Matrix(N, M, density, 5); // wu_id = 5
cells := cells1 + cells2;
// Create a dimension dataset
dims := MatDims.PartitionedFromCells(cells, 'A');  
// Make partitions
DATASET(Layout_Part) parts := int.Converted.FromCells(dims, cells);
// Convert parts back to cells
DATASET(Layout_Cell) cells_roundtrip := int.Converted.FromParts(parts);



Layout_Parts_Empty := RECORD
	UNSIGNED			  nodes;
    iTypes.node_t          node_id;
    iTypes.partition_t     partition_id;
    Types.dimension_t     block_row;
    Types.dimension_t     block_col;
    Types.dimension_t     first_row;
    Types.dimension_t     part_rows;
    Types.dimension_t     first_col;
    Types.dimension_t     part_cols;
    UNSIGNED			  cells;
END;
Layout_Cell cmp_cells(Layout_Cell l, Layout_Cell r) := TRANSFORM
  SELF.v := r.v - l.v;
  SELF := r;
END;

Layout_Parts_Empty reduce_parts(Layout_Part lr) := TRANSFORM
  SELF.nodes := nodes;
  SELF.cells := COUNT(lr.mat_part);
  SELF := lr;
END;
Layout_Result := RECORD
    Types.partition_t     partition_id;
    INTEGER     node_id;
    INTEGER     block_row;
    INTEGER     block_col;
    INTEGER     first_row;
    INTEGER     part_rows;
    INTEGER     first_col;
    INTEGER     part_cols;
    INTEGER     mat_size;
    INTEGER		mat_values;
END;

Layout_Result parts_cmp(Layout_Part l, Layout_Part r) := TRANSFORM
	SELF.partition_id := r.partition_id;
	SELF.node_id := r.node_id - l.node_id;
	SELF.block_row := r.block_row - l.block_row;
	SELF.block_col := r.block_col - l.block_col;
	SELF.first_row := r.first_row - l.first_row;
	SELF.part_rows := r.part_rows - l.part_rows;
	SELF.first_col := r.first_col - l.first_col;
	SELF.part_cols := r.part_cols - l.part_cols;
	SELF.mat_size := COUNT(r.mat_part) - COUNT(l.mat_part);
	SELF.mat_values := IF(r.mat_part != l.mat_part,1, 0);
END;

// Compare the roundtrip conversion results to the original
DATASET(Layout_Cell) round_trip_cmp := JOIN(cells, cells_roundtrip, 
  LEFT.x = RIGHT.x AND LEFT.y = RIGHT.y AND LEFT.wi_id = RIGHT.wi_id, cmp_cells(LEFT, RIGHT));

summary_rec := RECORD
	cell_count := COUNT(GROUP);
	value_errs := COUNT(GROUP, round_trip_cmp.v != 0);
	count_errs := COUNT(cells_roundtrip) - COUNT(cells);
	errors := COUNT(GROUP, round_trip_cmp.v != 0) + 
	  COUNT(cells_roundtrip) - COUNT(cells); // total errors
END;

// Summarize any errors in the comparison
round_trip_rslts := TABLE(round_trip_cmp, summary_rec);

parts_reduced := PROJECT(parts, reduce_parts(LEFT));
// Return a row for regular round_trip and one for round_trip with inserts.
EXPORT ConvertedIntMyr := WHEN(round_trip_rslts, override);
