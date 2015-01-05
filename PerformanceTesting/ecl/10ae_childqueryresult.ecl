//class=child
//class=memory

import $ as suite;
import suite.perform.config;
import suite.perform.format;
import suite.perform.files;
import suite.perform.util;

#option ('globalAutoHoist', false);

//MORE: This test should be very efficient - directly using the precalculated results from before.
//Whether it is or not is a different matter....

unsigned scale := IF(config.smokeTest, 0x1000, 0x10);
ds := files.generateSimpleScaled(0, scale);

resultRec := RECORD
    RECORDOF(ds);
    unsigned cnt;
END;

mkRows := DATASET(40, TRANSFORM({unsigned id}, SELF.id := COUNTER;));

resultRec t(ds l) := TRANSFORM
    SELF.cnt := COUNT(NOFOLD(DEDUP(NOFOLD(mkRows),id+l.id3)));
    SELF := l;
END;

p := PROJECT(ds, t(LEFT));
             
cnt := COUNT(NOFOLD(p)(cnt=40));

OUTPUT(cnt = config.simpleRecordCount DIV scale);
