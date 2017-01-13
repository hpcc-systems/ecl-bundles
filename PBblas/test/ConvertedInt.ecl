/*##############################################################################
## HPCC SYSTEMS software Copyright (C) 2016 HPCC Systems®.  All rights reserved.
############################################################################## */
/**
  * Test for PBblas/internal/Converted.ecl module
  * Converts from cells to partitions, and then back to cells
  * using Converted.FromCells and Converted.FromParts.
  * Then repeats the test with the "transpose" feature
  * (Transposes into parts and the transposes back into cells).
  *
  *
  */

IMPORT Std.System.Thorlib;
IMPORT $.^ as PBblas;
IMPORT PBblas.Types;
IMPORT PBblas.MatUtils;
IMPORT PBblas.internal as int;
IMPORT int.Types as iTypes;
IMPORT int.MatDims;
IMPORT $ as Tests;
IMPORT Tests.MakeTestMatrix as tm;
Layout_Cell := Types.Layout_Cell;
Layout_Part := iTypes.Layout_Part;
nodes := Thorlib.nodes();

max_partition_size_override := 1000;
override := #STORED('BlockDimensions_max_partition_size', max_partition_size_override);

// Test configuration Parameters -- modify these to vary the testing
N := 600;   // Number of rows
M := 500;      // Number of columns

density := 1.0; // 1.0 is fully dense. 0.0 is empty.
// End of config parameters


// Generate cell-based Matrix to test with
cells := tm.Matrix(N, M, density);

dims := MatDims.PartitionedFromCells(cells, 'A');
// Make partitions
DATASET(Layout_Part) parts := int.Converted.FromCells(dims, cells);
// Convert parts back to cells
DATASET(Layout_Cell) cells_roundtrip := int.Converted.FromParts(parts);

// Now test with Transposed
// Make partitions
t_dims := MatDims.TransposeDims(dims);
DATASET(Layout_Part) t_parts := int.Converted.FromCells(t_dims, cells, TRUE);
// Convert parts back to cells
DATASET(Layout_Cell) t_cells_roundtrip := int.Converted.FromParts(t_parts, TRUE);

Layout_Cell cmp_cells(Layout_Cell l, Layout_Cell r) := TRANSFORM
  SELF.v := r.v - l.v;
  SELF := r;
END;

Layout_Part reduce_parts(Layout_Part lr) := TRANSFORM
  SELF.mat_part := [COUNT(lr.mat_part)];
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
cells2 := SORT(cells, wi_id, x, y, LOCAL);
cells2_roundtrip := SORT(cells_roundtrip, wi_id, x, y);
DATASET(Layout_Cell) roundtrip_cmp := JOIN(cells2, cells2_roundtrip, 
  LEFT.wi_id = LEFT.wi_id AND LEFT.x = RIGHT.x AND LEFT.y = RIGHT.y, cmp_cells(LEFT, RIGHT));

t_cells2_roundtrip := SORT(t_cells_roundtrip, wi_id, x, y);
DATASET(Layout_Cell) t_roundtrip_cmp := JOIN(cells2, t_cells2_roundtrip, 
  LEFT.wi_id = LEFT.wi_id AND LEFT.x = RIGHT.x AND LEFT.y = RIGHT.y, cmp_cells(LEFT, RIGHT));
  
summary_rec := RECORD
	//STRING label := 'Normal';
	cell_count := COUNT(GROUP);
	value_errs := COUNT(GROUP, roundtrip_cmp.v != 0);
	count_errs := COUNT(cells_roundtrip) - COUNT(cells);
	errors := COUNT(GROUP, roundtrip_cmp.v != 0) + 
	  COUNT(cells_roundtrip) - COUNT(cells); // total errors
END;

t_summary_rec := RECORD
	//STRING label := 'Transposed';
	cell_count := COUNT(GROUP);
	value_errs := COUNT(GROUP, t_roundtrip_cmp.v != 0);
	count_errs := COUNT(t_cells_roundtrip) - COUNT(cells);
	errors := COUNT(GROUP, t_roundtrip_cmp.v != 0) + 
	  COUNT(t_cells_roundtrip) - COUNT(cells); // total errors
END;

// Summarize any errors in the comparison
roundtrip_rslts := TABLE(roundtrip_cmp, summary_rec);
t_roundtrip_rslts := TABLE(t_roundtrip_cmp, t_summary_rec);
// Return a row for regular round_trip and one for round_trip with inserts.
rslt := roundtrip_rslts + t_roundtrip_rslts;
EXPORT ConvertedInt := WHEN(rslt, override);

