/*##############################################################################
## HPCC SYSTEMS software Copyright (C) 2016 HPCC Systems®.  All rights reserved.
############################################################################## */

/**
  * Test for Std/PBblas/PB_dgemm.ecl
  * 
  * Utilizes two sets of test cases:
  * 1) Basic Tests --Tries many different variations of matrix sizes and parameters
  * 2) Myriad Tests -- Tests multiple multiplications of divergent matrixes in 
  *     one call.  Runs four times, once for each setting of transposeA and transposeB
  * For all test cases, compares the results to a non-partitioned call to blas.dgemm.
  * The parameter max_partition_size should not be changed without re-calibrating the
  * entire test.  It is set so that reasonably small matrixes can be used and will
  * still be partitioned.  
  * 
  * Indirectly exercises multiple internal use modules as well
  */

IMPORT $.^ as PBblas;
IMPORT PBblas.internal as int;
IMPORT PBBlas.Types;
IMPORT PBblas.Internal.Types as iTypes;
IMPORT Std.BLAS;

IMPORT $ as Tests;
IMPORT Tests.MakeTestMatrix as tm;
Layout_Cell := Types.Layout_Cell;
Layout_Dims := iTypes.Layout_Dims;
dimension_t := Types.dimension_t;
value_t := Types.value_t;

// Parameters to control test execution

// Don't change max_partition_size without careful consideration.  It is
// used to override the standard max partition size (1,000,000) so that 
// partitioning can be exercised without large matrixes.  This test will
// have problems with very large matrixes, as the results will be compared
// to a non-partitioned multiply.  Any matrix with more than 10,000,000
// cells may run out of memory during the reference computation.
max_partition_size := 100;
override := #STORED('BlockDimensions_max_partition_size', max_partition_size);

// Limit the amount of data shown in results to 1 unless errors, then show this many rows
data_rows_in_result := 10;


// Define parameters for test cases
REAL dense := 1.0;  // Density of 1.0 means that all cells will be populated (non-zero)
REAL sparse := .4;  // .4 means 40% of cells will be non-zero
REAL alpha := 6.25; // Arbitrary value for use as alpha (see PB_dgemm)
REAL beta := -1.3; // Arbitrary beta
// End test parameters

// RECORDs for test cases
// See test_cases and myr_test_cases below for explanations and warnings
Layout_TestCase := RECORD
  STRING tc_name;
  BOOLEAN transposeA; 
  BOOLEAN transposeB; 
  REAL alpha;
  dimension_t N;
  dimension_t M;
  dimension_t P; 
  BOOLEAN useC:=FALSE;
  REAL beta:=1.0;
  REAL A_density:=1.0;
  REAL B_density:=1.0;
  REAL C_density:=1.0;
END;

// Record to hold combinations of transposeA and transposeB for myriad testing
Layout_Variation := RECORD
  BOOLEAN transposeA;
  BOOLEAN transposeB;
END;

// Basic (i.e. non-myriad) test cases
// Try different shaped matrixes, different combinations of features (i.e. transposeA,
// transposeB, alpha, beta, C matrix (absent or present), etc.)
// Build up from very basic tests to exotic variations.
test_cases := DATASET([ 
  // {test_case_name, transposeA, transposeB, alpha, N, M, P, UseC, beta, A_density, B_density, C_density}
  // Basic squat (i.e. near square) matrix
  {'Squat', TRUE, FALSE, 1.0, 20, 18, 22},
  {'Squat', FALSE, FALSE, 1.0, 18, 22, 20},
  // Include a C addend
  {'Squat+C', FALSE, FALSE, 1.0, 20, 18, 22, TRUE, 1.0},
  //  Alpha
  {'Squat+C+alpha', FALSE, FALSE, alpha, 20, 18, 22, TRUE, 1.0},
  // Beta
  {'Squat+C+alpha+beta', FALSE, FALSE, alpha, 20, 18, 22, TRUE, beta},
  // Sparse
  {'Squat/sparse', FALSE, FALSE, alpha, 20, 18, 22, TRUE, beta, sparse, sparse, sparse},
  // Prime number of rows and columns to catch any errors in non-full partitions
  {'PrimeDimensions', FALSE, FALSE, alpha, 23, 19, 29, TRUE, beta, sparse, sparse, sparse},				
  // Tall A and transpose testing (note: test program creates transpose matrixes such
  //  that the final dimensions (after transpose) match N, M, and P
  {'TallA', FALSE, FALSE, alpha, 500, 3, 2, TRUE, beta, sparse, sparse, sparse},
  {'TallA+transA', TRUE, FALSE,alpha, 500, 3, 2, TRUE, beta, dense, dense, dense},
  {'TallA+transB', FALSE, TRUE, alpha, 500, 3, 2, TRUE, beta, sparse, sparse, sparse},
  {'TallA+transAB', TRUE, TRUE, alpha, 500, 3, 2, TRUE, beta, sparse, sparse, sparse},
  // Wide A
  {'WideA', FALSE, FALSE, alpha, 5, 500, 5, TRUE, beta, sparse, sparse, sparse},
  // Wide B
  {'WideB', FALSE, FALSE, alpha, 4, 3, 500, TRUE, beta, sparse, sparse, sparse},
  // Tiny matrix, should only have one partition
  {'Tiny', FALSE, FALSE, alpha, 5, 5, 5, TRUE, beta, dense, dense, dense},
  // Zero A
  //{'ZeroA', FALSE, FALSE, alpha, 31, 39, 11, TRUE, beta, 0.0, dense, dense} // Exception!!
  // Zero B
  {'ZeroB', FALSE, FALSE, alpha, 31, 39, 11, FALSE, beta, sparse, 0.0, sparse},
  // Zero A and B
  {'ZeroAB', FALSE, FALSE, alpha, 31, 39, 11, FALSE, beta, 0.0, 0.0, sparse},
  // Zero A, B, and C
  {'ZeroABC', FALSE, FALSE, alpha, 31, 39, 11, TRUE, beta, 0.0, 0.0, 0.0},
  {'Inner Product', FALSE, FALSE, alpha, 3, 500, 4, FALSE, beta, dense, dense, dense},
  {'Inner Product2', FALSE, FALSE, alpha, 7, 500, 6, TRUE, beta, sparse, sparse, dense}
  ], Layout_TestCase);
									
// Myriad test cases
// Note: For myriad tests, transposeA and transposeB are ignored (does all combinations)
// WARNING: For myriad tests, alpha and beta need to be the same for all test cases.
//       This is because there is a single alpha and beta parameter passed to PB_dgemm.
//       Comparisons will fail if mixed in these tests.
myr_test_cases := DATASET([
  // {test_case_name, transposeA(ignored), transposeB(ignored), alpha, N, M, P, UseC, beta, A_density, B_density, C_density}
  {'Squat_Myriad', FALSE, FALSE, alpha, 20, 18, 22, FALSE, beta},
  {'Squat2_Myriad', FALSE, FALSE, alpha, 18, 22, 20, TRUE, beta},
  {'Tall_Myriad', FALSE, FALSE, alpha, 123, 11, 17, TRUE, beta, sparse, sparse, sparse},
  {'IP_Myriad', FALSE, FALSE, alpha, 3, 500, 4, FALSE, beta, dense, dense, dense}, // Inner product uses special
  																				   // optimized path in PB_dgemm
  {'IP_Myriad2', FALSE, FALSE, alpha, 7, 1000, 6, TRUE, beta, sparse, dense, sparse}
  ], Layout_TestCase);

// All combinations of transposeA and transposeB
myr_variations := DATASET([
  {FALSE, FALSE},
  {FALSE, TRUE},
  {TRUE, FALSE},
  {TRUE, TRUE}
  ], Layout_Variation);

// This RECORD type contains the test-case information, plus the results from the
// call to PB_dgemm.  It is then passed to blas.dgemm for to include its results in
// Layout_NonBlockResult, which adds the blas result (see Layout_NonBlockResult below)
Layout_BlockResult := RECORD(Layout_TestCase)
  DATASET(Layout_Cell) A;
  DATASET(Layout_Cell) B;
  DATASET(Layout_Cell) C;
  DATASET(Layout_Cell) result;
  UNSIGNED wi_id;
END;
// Perhaps misnamed.  It is a composite of the original
// test_case info, the results from the block (i.e. PB_dgemm) method, as well as
// the results from the blas.dgemm call used for comparison
Layout_NonBlockResult := RECORD(Layout_BlockResult)
  DATASET(Layout_Cell) nb_result;
END;

// Generate test data for non-myriad tests
Layout_BlockResult make_test_data(Layout_TestCase tc, UNSIGNED4 ctr, UNSIGNED tc_count) := TRANSFORM
  N1 := IF(tc.transposeA, tc.M, tc.N); // N used for A's dim
  N3 := tc.N;                          // N used for C's dim (never transposed)
  M1 := IF(tc.transposeA, tc.N, tc.M); // M used for A's dim
  M2 := IF(tc.transposeB, tc.P, tc.M); // M used for B's dim
  P2 := IF(tc.transposeB, tc.M, tc.P); // P used for B's dim
  P3 := tc.P;                          // P used for C's dim (never transposed)  
  c:= (ctr-1) % tc_count + 1;
  SELF.A := tm.Matrix(N1, M1, tc.A_density, c);
  SELF.B := tm.Matrix(M2, P2, tc.B_density, c);
  SELF.C := IF(tc.useC, tm.Matrix(N3, P3, tc.C_density, c), DATASET([], Layout_Cell));
  SELF.result := DATASET([], Layout_Cell);
  SELF.wi_id := c;
  SELF := tc;
END;

// Combine the cells from all myriad test_cases into a single test.
Layout_BlockResult make_myriad(Layout_BlockResult l, Layout_BlockResult r) := TRANSFORM
	SELF.A :=l.A + r.A;
	SELF.B := l.B + r.B;
	SELF.C := l.C + r.C;
	SELF.result := r.result;
	SELF := r;
END;

// Create variations of the myriad test for each combo of transposeA and B
Layout_TestCase extend_myr_tcs(myr_variations l, Layout_TestCase r) := TRANSFORM
  SELF.transposeA := l.transposeA;
  SELF.transposeB := l.transposeB;
  SELF := r;
END;

// Perform the myriad testing.
// Extend the myriad test cases by combining with all values of transposeA and transposeB
myr_test_cases2 := JOIN(myr_variations, myr_test_cases, TRUE, extend_myr_tcs(LEFT, RIGHT), ALL);
// Create test data for each extended test case
td := PROJECT(myr_test_cases2, make_test_data(LEFT, COUNTER, COUNT(myr_test_cases)));
td2 := SORT(td, transposeA, transposeB);
// Combine all of the test cases with the same transposeA and transposeB by
// concatenating the cells.  This makes the test myriad. Each original test had
//  its own work-item id.
myr_test_data := ROLLUP(td2, LEFT.transposeA = RIGHT.transposeA AND 
       LEFT.transposeB = RIGHT.transposeB, make_myriad(LEFT, RIGHT));

// Process each myriad extended test case.  Calls PB_dgemm with all of the myr_test_cases
// combined.
Layout_BlockResult process_myr_tcs(Layout_BlockResult l)  := TRANSFORM
  myr_result := PBblas.gemm(l.transposeA, l.transposeB, l.alpha, l.A, 
          l.B, l.C, l.beta);
  SELF.result := myr_result;
  SELF := l;
END;

// Separate the myriad test cases and results into discrete cases for comparison
Layout_BlockResult separate_myr_results(Layout_BlockResult l, UNSIGNED c) := TRANSFORM
  SELF.A := l.A(wi_id=c);
  SELF.B := l.B(wi_id=c);
  SELF.C := l.C(wi_id=c);
  SELF.result := l.result(wi_id=c);
  SELF.transposeA := l.transposeA;
  SELF.transposeB := l.transposeB;
  SELF.wi_id := c;
  SELF := myr_test_cases[c];
END;

// Do the multiply on each of the myriad test cases (one per transpose A/B combo)
myr_result := PROJECT(myr_test_data, process_myr_tcs(LEFT));
// Now separate the individual cases (and results) back out so that we can compare with
//  blas.dgemm results (non-myriad)
myr_result_sep := NORMALIZE(myr_result,  COUNT(myr_test_cases), separate_myr_results(LEFT, COUNTER));

// Make the non-myriad calls to PB_dgemm for each test case
Layout_BlockResult do_block(Layout_TestCase tc, UNSIGNED ctr) := TRANSFORM
  N1 := IF(tc.transposeA, tc.M, tc.N); // N used for A's dim
  N3 := tc.N;                          // N used for C's dim (never transposed)
  M1 := IF(tc.transposeA, tc.N, tc.M); // M used for A's dim
  M2 := IF(tc.transposeB, tc.P, tc.M); // M used for B's dim
  P2 := IF(tc.transposeB, tc.M, tc.P); // P used for B's dim
  P3 := tc.P;                          // P used for C's dim (never transposed)  
  
  A := tm.Matrix(N1, M1, tc.A_density, ctr);
  B := tm.Matrix(M2, P2, tc.B_density, ctr);
  C := IF(tc.useC, tm.Matrix(N3, P3, tc.C_density, ctr),DATASET([], Layout_Cell));
  rslt := PBblas.gemm(tc.transposeA, tc.transposeB, tc.alpha, A, B, C, tc.beta);
  SELF.A := A;
  SELF.B := B;
  SELF.C := C;
  SELF.result := SORT(rslt, x, y);
  SELF.wi_id := ctr;
  //SELF.result := SELF.A;
  SELF := tc;
END;

// Reduce the number of cells in the output to a reasonable number for display
// convenience.  See configuration parameter data_rows_in_result above.
Layout_BlockResult reduce_block_result(Layout_BlockResult in_result) := TRANSFORM
  SELF.A := in_result.A[1..data_rows_in_result];
  SELF.B := in_result.B[1..data_rows_in_result];
  SELF.C := in_result.C[1..data_rows_in_result];
  SELF.result := in_result.result[1..data_rows_in_result];
  SELF := in_result;
END;

// Make the call to blas.dgemm to provide baseline results for comparison
// of each test case
Layout_NonBlockResult do_non_block(Layout_BlockResult tc) := TRANSFORM
  N1 := IF(tc.transposeA, tc.M, tc.N); // N used for A's dim
  N3 := tc.N;                          // N used for C's dim (never transposed)
  M1 := IF(tc.transposeA, tc.N, tc.M); // M used for A's dim
  M2 := IF(tc.transposeB, tc.P, tc.M); // M used for B's dim
  P2 := IF(tc.transposeB, tc.M, tc.P); // P used for B's dim
  P3 := tc.P;                          // P used for C's dim (never transposed)  
  a_r8s := int.MakeR8Set(N1, M1, 1, 1, tc.A);
  b_r8s := int.MakeR8Set(M2, P2, 1, 1, tc.B);
  c_r8s := int.MakeR8Set(N3, P3, 1, 1, tc.C);
  SET OF REAL8 nb_result_raw := BLAS.dgemm(tc.transposeA, tc.transposeB,
    tc.N,tc.P,tc.M,tc.alpha, a_r8s, b_r8s, tc.beta, c_r8s);
  nb_result :=  SORT(int.FromR8Set(nb_result_raw, tc.N), x,y);
  SELF.nb_result := nb_result;
  SELF := tc;
END;

// Non-myriad tests.  For each test case, do PB_dgemm and blas.dgemm, and compare the results
DATASET(Layout_BlockResult) block_result := PROJECT(test_cases, do_block(LEFT, COUNTER));
DATASET(Layout_BlockResult) block_result_min := PROJECT(block_result, reduce_block_result(LEFT));
DATASET(Layout_NonBlockResult) combined_result := PROJECT(block_result, do_non_block(LEFT));

// Compare the myriad results with the blas.dgemm results
DATASET(Layout_NonBlockResult) combined_result_myr := PROJECT(myr_result_sep, do_non_block(LEFT));

// Summarizes the results of each test case
Layout_Results := RECORD(Layout_TestCase)
  UNSIGNED value_errors;
  UNSIGNED count_errors;
  UNSIGNED total_errors;
  DATASET(Layout_Cell) result;
  DATASET(Layout_Cell) nb_result;
END;

// Used to compare cells between the result and the reference
Layout_JoinCells := RECORD(Layout_Cell)
  REAL8 v2;
  REAL8 diff;
END;

// Compares the values of each corresponding cell from result and reference
Layout_JoinCells compare_cells(Layout_Cell l, Layout_Cell r) := TRANSFORM
  SELF.v2 := r.v;
  SELF.diff := ROUND(r.v,2) - ROUND(l.v, 2);
  SELF := l;
END;

// Join the cells from the result and reference and call compare_cells
Layout_Results compare(Layout_NonBlockResult tc) := TRANSFORM
  DATASET(Layout_JoinCells) test := JOIN(tc.result,  tc.nb_result,LEFT.x = RIGHT.x AND LEFT.y = RIGHT.y, compare_cells(LEFT, RIGHT), RIGHT OUTER);
  SELF.count_errors := ABS(COUNT(tc.nb_result) - COUNT(tc.result));
  SELF.value_errors := COUNT(test(test.diff != 0));
  SELF.total_errors := SELF.count_errors + SELF.value_errors;
  total_errors := SELF.count_errors + SELF.value_errors;
  SELF.result := IF(total_errors > 0, tc.result[1..data_rows_in_result], tc.result[1..1]);
  SELF.nb_result := IF(total_errors > 0, tc.nb_result[1..data_rows_in_result], tc.nb_result[1..1]);
  SELF := tc;
END;

// Summarize the results of the tests by counting value and cell-count errors
DATASET(Layout_Results) detail := PROJECT(combined_result, compare(LEFT));
DATASET(Layout_Results) detail_myr := PROJECT(combined_result_myr, compare(LEFT));

// Combine the error counts from all the test cases into one summary error
summary_rec := RECORD
  total_tests := COUNT(GROUP);
  total_errs := COUNT(GROUP, detail.total_errors > 0);
END;
// Combine the error counts from all the test cases into one summary error (myriad)
summary_rec_myr := RECORD
  total_tests := COUNT(GROUP);
  total_errs := COUNT(GROUP, detail_myr.total_errors > 0);
END;

summary := TABLE(detail, summary_rec);
summary_myr := TABLE(detail_myr, summary_rec_myr);

// Combine myriad and non-myriad results
full_summary := summary + summary_myr;
full_detail := detail + detail_myr;

// Return one record per test case if full_detail.  Change to full_summary if summarization
// to two records (myr and non-myr) is desired.
// Override sets the max_partition_size in BlockDimensions to a smaller number for testing.
EXPORT Multiply := WHEN(full_detail, override);


