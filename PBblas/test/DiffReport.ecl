/*##############################################################################
## HPCC SYSTEMS software Copyright (C) 2016 HPCC Systems®.  All rights reserved.
############################################################################## */
// Difference report for testing
IMPORT $.^ as PBblas;
IMPORT PBblas.internal as int;
IMPORT PBblas.Types;
IMPORT int.Types as iTypes;
dimension_t := Types.dimension_t;
value_t     := Types.value_t;
Layout_Cell := Types.Layout_Cell;
Layout_Part := iTypes.Layout_Part;
Epsilon := 0.000001;

EXPORT DiffReport := MODULE
  EXPORT Text_Diff_Missing      := 'Missing';
  EXPORT Text_Diff_Added        := 'Added';
  EXPORT Text_Diff_Different    := 'Different';
  EXPORT Text_Diff_Unknown      := 'Unknown';
  EXPORT Diffs_Kept := 50;
  EXPORT Layout_Diff := RECORD
    dimension_t         cell_row;
    dimension_t         cell_col;
    value_t             v1;
    value_t             v2;
    value_t             diff;
    STRING              msg;
  END;
  EXPORT Layout_TestResult := RECORD
    UNSIGNED4           errors;
    UNSIGNED4           exact;
    UNSIGNED            small;
    STRING              TestName;
    DATASET(Layout_Diff)samples;
  END;
  Layout_Diff cmpr(Layout_Cell s, Layout_Cell t) := TRANSFORM
    // present with zero value same as missing
    difference      := s.v - t.v;
    SELF.cell_row   := IF(s.x>0, s.x, t.y);
    SELF.cell_col   := IF(s.y>0, s.y, t.y);
    SELF.diff       := difference / s.v;
    SELF.v1         := s.v;
    SELF.v2         := t.v;
    SELF.msg        := MAP(difference=0     => '',
                           s.x = t.x        => Text_Diff_Different,
                           s.x = 0          => Text_Diff_Added,
                           t.x = 0          => Text_Diff_Missing,
                           Text_Diff_Unknown);
  END;
  Layout_TestResult roll(DATASET(Layout_Diff) dfs, STRING tn) := TRANSFORM
    SELF.TestName := tn;
    SELF.exact   := COUNT(dfs(msg=''));
    SELF.small   := COUNT(dfs(msg <> '' AND ABS(diff)<=Epsilon));
    SELF.errors  := COUNT(dfs(ABS(diff)>Epsilon));
    SELF.samples := CHOOSEN(dfs(ABS(diff)>Epsilon), Diffs_Kept);
  END;
  EXPORT Compare_Cells(STRING testName,
                       DATASET(Layout_Cell) std,
                       DATASET(Layout_Cell) tst) := FUNCTION
    d0 := JOIN(std, tst,
               LEFT.x=RIGHT.x AND LEFT.y=RIGHT.y,
               cmpr(LEFT, RIGHT), FULL OUTER);
    d1 := GROUP(d0, TRUE) : ONWARNING(2029, ignore);
    r1 := ROLLUP(d1, GROUP, roll(ROWS(LEFT), testName));
    RETURN r1;
  END;
  EXPORT Compare_Parts(STRING testName,
                       DATASET(Layout_Part) std,
                       DATASET(Layout_Part) tst) := FUNCTION
    s0 := int.Converted.FromParts(std);
    t0 := int.Converted.FromParts(tst);
    r0 := Compare_Cells(testName, s0, t0);
    RETURN r0;
  END;
END;