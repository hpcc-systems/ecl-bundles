//class=memory
//class=sort
//class=stress

import $ as suite;
import suite.perform.config;
import suite.perform.format;
import suite.perform.files;

inRec := { unsigned8 delta; };

processN(unsigned num) := FUNCTION 
    ds := files.generateN(0, num);
    s1 := sort(ds, id3);
    s2 := SORTED(NOFOLD(s1), id3, local, assert);
    ret := TABLE(NOFOLD(s2), { unsigned8 cnt := COUNT(group) });
    RETURN PROJECT(ret, TRANSFORM(inRec, SELF.delta := LEFT.cnt - num));
END;

start := 90;
scale := 0.0025;
numIters := 1;

iters := LOOP(DATASET([], inRec),
              numIters, false, true, processN((COUNTER + start) * scale * config.simpleRecordCount));

output(count(iters(delta != 0)));
