Test Summary
============

This file contains a list of all the tests within the test suite, and what particular things they are trying to test.  The main divisions are the following:

| 01.     processing/memory speed
| 01b-e.  disk speed
| 02-03.  SORT
| 04.     JOIN 

01 Very basic row operations
++++++++++++++++++++++++++++

01a - Raw record creation
-------------------------

These tests create lots of records, and test how different sources work

| 01aa. raw create/destroy row speed
| 01ab. unordered combine of rows from multiple sources [ how well does the multi threaded concat work ]
| 01ac. ordered combine of rows from multiple sources [ concat is unthreaded ]
| 01ad - single input, duplicate the output n-ways (outputs overlap)
| 01ae - single input, split the output n-ways (no overlap between outputs)
| 01ag..al - 2,4,8,12,16,32 way unordered append - tests scaling of the multi threaded concat.

01b - Raw disk write speed
--------------------------

| 01ba - write 32b row to a disk file, uncompressed
| 01bb - write 32b row to a disk file, compressed
| 01bc - write 82b (with spaces) to a disk file, uncompressed
| 01bd - write 82b (with spaces) to a disk file, compressed
| 01be - write csv to a disk file, uncompressed
| 01bf - write xml to a disk file, uncompressed

01c - Raw disk read speed
-------------------------

| 01ca - read 32b row to a disk file, uncompressed
| 01cb - read 32b row to a disk file, compressed
| 01cc - read 82b (with spaces) to a disk file, uncompressed
| 01cd - read 82b (with spaces) to a disk file, compressed
| 01ce - read csv to a disk file, uncompressed
| 01cf - read xml to a disk file, uncompressed

01d - Parallel disk write speed
-------------------------------

| 01da - parallel write to disk (rows distributed among outputs)

01e - Disk aggregation (like 01c, but with little row creation overhead)
------------------------------------------------------------------------

| 01ea - sum 32b row to a disk file, uncompressed
| 01eb - sum 32b row to a disk file, compressed
| 01ec - sum 82b (with spaces) to a disk file, uncompressed
| 01ed - sum 82b (with spaces) to a disk file, compressed
| 01ee - sum csv to a disk file, uncompressed
| 01ef - sum xml to a disk file, uncompressed

02 Sorting
++++++++++

02a - Disk sorting
------------------

| 02aa - sort rows from disk locally
| 02ab - sort rows from disk globally

02b - Sorting created records (no disk hit)
-------------------------------------------

| 02ba - sort rows locally
| 02bb - sort rows globally
| 02bc - A very big group sort.
| 02bd - Sort local with duplicates (only 1M unique keys)
| 02be - Sort local with duplicates (only 4K unique keys)
| 02bf - Sort global with duplicates (only 1M unique keys)
| 02bg - Sort global with duplicates (only 4K unique keys)
| 02bh - Sort global with duplicates (a skewed distribution)

02c - Multiple sorts in parallel
--------------------------------
| 02ca - 4 Parallel local sorts (same total records)
| 02cb - 16 Parallel local sorts (same total records)
| 02cc - 4 Parallel global sorts (same total records)
| 02cd - 16 Parallel global sorts (same total records)
| 02ce - local sort 4x total records
| 02cf - local sort 16x total records
| 02cg - global sort 4x total records
| 02ch - global sort 16x total records
| 02ci - 16 Parallel local sorts (16x total records)
| 02cj - 16 Parallel global sorts (16x total records)

03 Distribution
+++++++++++++++

03a - Distribution from disk
----------------------------
| 03aa - Distribute from disk file

03b - Distribution
------------------
| 03ab - Distribute  created rows

03c - Parallel Distribution
---------------------------
| 03ca - Distribute 4 datasets in parallel (same total records)
| 03cb - Distribute 16 datasets in parallel (same total records)

04 Joins
++++++++

| 04aa - Simple join between two datasets, 1 match per row.
| 04ab - Simple join between two datasets, 1 match per row. unsorted output
| 04ac - Simple join between two datasets, 1 match per row. parallel join
| 04ba - Simple join between two datasets, 4 matches per row.
| 04bb - Simple join between two datasets, 4 matches per row. unsorted output
| 04bc - Simple join between two datasets, 4 matches per row. parallel join
| 04ca - Simple join between two datasets, 64 matches per row.
| 04cb - Simple join between two datasets, 64 matches per row. unsorted output
| 04cc - Simple join between two datasets, 64 matches per row. parallel join
| 04cd - Simple join between two datasets, 64 matches per row. lookup join
| 04da - Simple join between two datasets, 4K matches per row.
| 04db - Simple join between two datasets, 4K matches per row. unsorted output
| 04dc - Simple join between two datasets, 4K matches per row. parallel join
| 04dd - Simple join between two datasets, 4K matches per row. lookup join

05 Grouped aggregation
++++++++++++++++++++++

| 05aa - Summarise into 64 groups, sort->group->aggregate
| 05ab - Summarise into 64 groups, hash aggregate
| 05ba - Summarise into 1M groups, sort->group->aggregate
| 05ba - Summarise into 1M groups, hash aggregate
