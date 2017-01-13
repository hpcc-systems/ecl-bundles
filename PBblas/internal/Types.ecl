/*############################################################################
## HPCC SYSTEMS software Copyright (C) 2016 HPCC Systems®.  All rights reserved.
############################################################################## */

IMPORT $.^ as PBblas;
IMPORT PBblas.Types as eTypes;
dimension_t := eTypes.dimension_t;
partition_t := eTypes.partition_t;
work_item_t := eTypes.work_item_t;

/**
  * Internal Types for the Parallel Block Basic Linear Algebra Sub-programs support
  * WARNING: attributes marked with WARNING can not be changed without making
  * corresponding changes to the C++ attributes.
  */
EXPORT Types := MODULE
  /**
    * Type for partition id -- only supports up to 64K partitions
    */
  EXPORT partition_t  := UNSIGNED2;
  /**
    * Type for node id -- only supports up to 64K nodes
    */
  EXPORT node_t       := UNSIGNED2;
  /**
    * Type for matrix cell values
    * 
    * WARNING: type used in C++ attribute
    */
  EXPORT value_t      := REAL8;
  /**
    * Type for matrix label.  Used for Matrix dimensions (see Layout_Dims)
    * and for partitions (see Layout_Part)
    */
  EXPORT m_label_t    := STRING3;
  /**
    * Type for dense matrix storage
    *
    * Stored as a set of values in column/row order:
    * [r1c1, r2c1, ... rMc1,
    *  r1c2, r2c2, ... rMc2,
    *  .
    *  .
    *  .
    *  r1cN, r2cN, ... rMcN]
    * 
    * WARNING: type used in C++ attribute
    * Note: This type is not distributed, so should only be used to represent
    * small matrixes(< 1M cells).  Larger matrixes can be represented
    * using Layout_Cell or Layout_Part, both of which can be distributed.
    * A dense matrix can be converted to a scalable sparse form (DATASET(Layout_Cell))
    * using the utility module FromR8Set
    *
    * @see		Layout_Cell
    * @see		Layout_Part
    * @see		Std/PBblas/FromR8Set.ecl
    */
  EXPORT matrix_t     := SET OF REAL8;

  /**
    * Enumeration for Partitioning Type
    */
  EXPORT PartitionType := ENUM(UNSIGNED1, single=1, square, row, column);
  p_types := DATASET([
    {'single', PartitionType.single},
    {'square', PartitionType.square},
    {'row', PartitionType.row},
  	{'column', PartitionType.column}],{STRING6 name, PartitionType val});
  p_types_dict := DICTIONARY(p_types, {val => name});
  /**
    * Translation of PartitionType enumeration
    */
  EXPORT PartitionTypeString(PartitionType pt) := p_types_dict[pt].name;
  EXPORT OpType := ENUM(UNSIGNED1, 
                      single=1, // A single matrix of any shape
                      multiply, // Three interlocked matrixes 'A', 'B', and 'C'
                      solve_ax, // Two interlocked matrixes  'A' and 'B'
                      solve_xa, // Two interlocked matrixes  'A' and 'B'
                      square, // One matrix.  Uses the largest of rows or columns for both.
                      parallel // Two or more matrixes that need to be the same shape
                      );
  /**
    * Type for matrix universe number
    *
    * Allow up to 64k matrices in one universe
    *
    */
  EXPORT t_mu_no      := UNSIGNED2; //Allow up to 64k matrices in one universe
  
  /**
    * Alternate form for storage of large matrixes as a set of partitions
    * Each partition holds the dense form of a piece of the matrix (see matrix_t)
    * as well as information about its relationship to the larger matrix.
    * The full matrix is then carried as DATASET(Layout_Part).
    * Utility module Converted provides functions for converting a matrix in cell
    * form (see Layout_cell) to partitions and vice versa.
    * This form is primarily used internally to PBblas functions, but can also
    * be used as an intermediate form to avoid repeated conversions from cell
    * form.
    * A work-item id field allows multiple matrixes to be carried in the
    * same dataset.  This supports the "myriad" style interface whereby the
    * same operation can be performed on multiple sets of matrixes at once.
    * The m_label field allows for the separation of multiple matrixes with the
    * same wi_id for operations requiring multiple matrixes.  This allows
    * multiple work-items with multiple matrixes each to be carried in the same
    * dataset.

    * @field wi_id          Work Item Number -- An identifier from 1 to 64K-1 that
    *                         separates and identifies individual matrixes
    * @field m_label        A user provided label indicating to which matrix the dimensions
    *                       apply, when used to describe a set of related matrixes (e.g.,
    *                       'A', 'B', and 'C') for the same work item used in an operation.    * @field partition_id	A unique ID for this partition within the matrix
    * @field partition_id   The 1-based id of this partition, unique within a work-item
    * @field node_id		The node on which this partition is stored
    * @field m_rows         The number of rows in the full matrix
    * @field m_cols         The number of columns in the full matrix
    * @field row_blocks     The number of row partitions in use
    * @field col_blocks     The number of column partitions in use
    * @field block_row		The row of this partition within the block partition matrix
    * @field block_col		The column of this partition "
    * @field part_rows		The number of rows stored within this partition
    * @field part_cols		The number of columns stored within this partition
    * @field first_row		The first row of the original matrix stored within this
    *						partition
    * @field first_col		The first column of the original matrix stored within this
    *						partition
    * @field mat_part		The dense representation of the cells values within this
    *						partition (see matrix_t)
    * @see		matrix_t
    * @see		Layout_Cell
    * @see		Std/PBblas/Converted
    */
  EXPORT Layout_Part  := RECORD
    m_label_t       m_label;
    work_item_t		  wi_id:=1;  // 1 based work-item number
    partition_t     partition_id;
    node_t          node_id;   // zero based
    dimension_t     m_rows;
    dimension_t     m_cols;
    dimension_t     row_blocks;
    dimension_t     col_blocks;
    dimension_t     block_row;
    dimension_t     block_col;
    dimension_t     part_rows;
    dimension_t     part_cols;
    dimension_t     first_row;
    dimension_t     first_col;
    matrix_t        mat_part;
  END;

  /**
    * Represents the relationship of a partition to the partition holding the
    * results of a matrix operation.  This is used internally to PBblas functions
    * to tie an input partition to its output.  It is not relevant to users of
    * PBblas.
    *
    * @field t_part_id		The output partition to which this partition is related
    * @field t_node_id		The node on which the output partition is located
    * @field t_block_row	The row of the output partition within its partition matrix
    * @field t_block_col	The column of the output partition within its partition matrix
    * @field t_term			A row/column number used to correlate related input partitions used
    *						in calculating the results of the output partition
    */
  EXPORT Layout_Target := RECORD
    partition_t     t_part_id;
    node_t          t_node_id;
    dimension_t     t_block_row;
    dimension_t     t_block_col;
    dimension_t     t_term;
    Layout_Part;
  END;
  /**
    * Record format for matrix and matrix partition dimensions.  Each record describes
    * A single matrix or matrix partition.  Partitions use all of the fields, while
    * a non-partitioned matrix only uses the first two (i.e. m_rows and m_cols).
    * @field m_label A user provided label indicating to which matrix the dimensions
    *                apply, when used to describe a set of related matrixes (e.g.,
    *                'A', 'B', and 'C') for the same work item used in an operation.
    * @field m_rows The number of rows in the full matrix
    * @field m_cols The number of colums in the full matrix
    * @field block_rows The number of rows in each partition of the matrix
    * @field block_cols The number of columns in each partition
    * @field row_blocks The number of row partitions in use for the matrix
    * @field col_blocks The number of column partitions in use for the matrix
    */
  EXPORT Layout_Dims := RECORD
  	m_label_t m_label;
  	work_item_t wi_id;
  	dimension_t m_rows;
  	dimension_t m_cols;
  	dimension_t block_rows:=0; // Number of rows in each partition
  	dimension_t block_cols:=0; // Number of cols in each partition
  	dimension_t row_blocks:=0; // Number of row partitions
  	dimension_t col_blocks:=0; // Number of col partitions
  END;
  /** 
    * Record for a list of work-item ids used internally
    *
    * @field wi_id  The wi_id, typically from a myriad set of matrixes
    *
    */
  EXPORT Layout_WI_ID := RECORD
  	work_item_t wi_id;
  END;
END;