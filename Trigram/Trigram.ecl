EXPORT Trigram := MODULE
  EXPORT REAL8 unicode_compare(UNICODE l_str, UNICODE r_str) := FUNCTION
    UNICODE1 begin_text := u'\0002';
    UNICODE1 end_text := u'\0003';
    tgram_rec := RECORD
      UNSIGNED2 l_count;
      UNSIGNED2 r_count;
      UNSIGNED2 common;
      UNICODE3 t_gram;
    END;
    ds := DATASET([{l_str, r_str}], {UNICODE l_str, UNICODE r_str});
    // make the bags of trigrams
    tgram_rec make_tg(RECORDOF(ds) d, UNSIGNED c, UNSIGNED1 pick) := TRANSFORM
      UNICODE  w_str := CHOOSE(pick, d.l_str, d.r_str);
      UNICODE3 first_str := begin_text + w_str[1..2];
      UNICODE3 mid_str := w_str[c-1..c+1];
      UNICODE3 last_str := w_str[c-1..c] + end_text;
      SELF.t_gram := MAP(c BETWEEN 2 AND LENGTH(w_str)-1  => mid_str,
                         c = 1                            => first_str,
                         last_str);
      SELF.l_count := IF(pick = 1, 1, 0);
      SELF.r_count := IF(pick = 1, 0, 1);
      SELF.common := 0;
    END;
    l_tgrams := NORMALIZE(ds, LENGTH(LEFT.l_str), make_tg(LEFT, COUNTER, 1);
    r_tgrams := NORMALIZE(ds, LENGTH(LEFT.r_str), make_tg(LEFT, COUNTER, 2);
    indv_rec := SORT(l_tgrams+r_tgrams, t_gram);
    // roll for easy counting for easy counting
    tgram_rec roll_tgram(tgram_rec accum, tgram_rec next) := TRANSFORM
      SELF.t_gram := accum.t_gram;
      SELF.l_count := accum.l_count + next.l_count;
      SELF.r_count := accum.r_count + next.r_count;
      SELF.common  := MIN(SELF.l_count, SELF.r_count);
    END;
    roll_rec := ROLLUP(indv_rec, roll_tgram(LEFT,RIGHT), t_gram);
    common_card := SUM(roll_rec, common);
    tot_card := SUM(roll_rec, l_count) + SUM(roll_rec, r_count);
    REAL8 ret_val := MAP(LENGTH(l_str)=0 AND LENGTH(r_str)=0  => 1.0,
                         LENGTH(l_str)=0                      => 0.0,
                         LENGTH(r_str)=0                      => 0.0,
                         l_str = r_str                        => 1.0,
                         LENGTH(l_str)=1 OR LENGTH(r_str)=1   => 0.0,
                         common_card/tot_card);
    RETURN ret_val;
  END;
  // Test cases
  Test_Rec := RECORD
    UNICODE str1;
    UNICODE str2;
  END;
  Test_Result := RECORD
    UNICODE str1;
    UNICODE str2;
    REAL8 score;
  END;
  Test_Result test(Test_Rec re) := TRANSFORM
    SELF.score := unicode_compare(re.str1, re.str2);
    SELF := re;
  END;
  test_data := DATASET([{u'a', u''}, {u'a', u'a'}, {u'a', u'b'},
                      {u'abcdefg', u'acbdefg'}], Test_Rec);
  test_run := PROJECT(test_data, test(LEFT));
  EXPORT Unit_Test := OUTPUT(test_run);
END;