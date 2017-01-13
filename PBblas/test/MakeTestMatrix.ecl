IMPORT $.^ as PBblas;
IMPORT PBblas.Types;
Layout_Cell := Types.Layout_Cell;
// Generate test data

EXPORT MakeTestMatrix := MODULE
  // Generate test data
  SHARED UNSIGNED rmax := POWER(2, 32) - 1; // Max value for use with RANDOM()
  SHARED modulus := 137; // A large prime number to keep the value of cells within reason to avoid fp errors
  SHARED W_Rec := RECORD
    STRING1 x:= '';
  END;
  SHARED W0 := DATASET([{' '}], W_Rec);
  SHARED Layout_Cell gen(UNSIGNED4 c, UNSIGNED4 NumRows, REAL8 v, REAL density, UNSIGNED wi_id=1):=TRANSFORM
    SELF.x := ((c-1)  %  NumRows) + 1;
    SELF.y := ((c-1) DIV NumRows) + 1;
    SELF.wi_id := wi_id;
    r := RANDOM();
    // Make sure we have at least one cell regardless of the density setting (i.e. don't skip 1,1),
    //  except if the density is 0.0, which is a way to force a zero matrix for specific test cases.
    SELF.v := IF((density > 0.0 AND SELF.x = 1 AND SELF.y = 1) OR r / rmax <= density, v, SKIP);
  END;
  offset := 250;
  SHARED REAL8 F_A(UNSIGNED4 c) := 3.0*POWER(c%modulus,1.1) -5.0*c%modulus - offset;

 // Generate cell-based Matrix
  EXPORT MatrixPersist(UNSIGNED N, UNSIGNED M, REAL density=1.0, UNSIGNED wi_id=1, STRING test_id='ANY') := FUNCTION
    cells := NORMALIZE(W0, N*M, gen(COUNTER, N, F_A(COUNTER), density, wi_id)) : 
      PERSIST('M_' + test_id + '_' + wi_id + '_' +N+'_'+M+'_'+density);
    return cells;
  END;

  EXPORT Matrix(UNSIGNED N, UNSIGNED M, REAL density=1.0, UNSIGNED wi_id=1) := FUNCTION
    cells := NORMALIZE(W0, N*M, gen(COUNTER, N, F_A(COUNTER), density, wi_id));
    cells2 := DISTRIBUTE(cells);
    return cells2;
  END;
  random_max := 500.0;
  SHARED Layout_Cell genRandom(UNSIGNED c, UNSIGNED NumRows, REAL density, UNSIGNED wi_id=1) := TRANSFORM
    SELF.x := ((c-1) % NumRows) + 1;
    SELF.y := ((c-1) DIV NumRows) + 1;
    SELF.wi_id := wi_id;
    v := RANDOM() / rmax * random_max * 2 - random_max;
    r := RANDOM();
    SELF.v := IF((density > 0.0 AND SELF.x = 1 AND SELF.y = 1) OR r / rmax < density, v, SKIP);
  END;
  EXPORT Random(UNSIGNED N, UNSIGNED M, REAL density=1.0, UNSIGNED wi_id=1) := FUNCTION
    cells := NORMALIZE(W0, N*M, genRandom(COUNTER, N, density, wi_id));
    cells2 := DISTRIBUTE(cells);
    return cells2;
  END;
 // Generate cell-based Matrix
  EXPORT RandomPersist(UNSIGNED N, UNSIGNED M, REAL density=1.0, UNSIGNED wi_id=1, STRING test_id='ANY') := FUNCTION
    cells := NORMALIZE(W0, N*M, genRandom(COUNTER, N, density, wi_id)) : 
      PERSIST('RM_' + test_id + '_' + wi_id + '_' +N+'_'+M+'_'+density);
    return cells;
  END;
END;

