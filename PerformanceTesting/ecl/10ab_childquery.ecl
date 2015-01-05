//class=child
//class=memory

import $ as suite;
import suite.perform.config;
import suite.perform.format;
import suite.perform.files;
import suite.perform.util;

unsigned scale := IF(config.smokeTest, 0x1000, 0x10);
ds := files.generateSimpleScaled(0, scale);

resultRec := RECORD
    RECORDOF(ds);
    unsigned cnt;
END;

resultRec t(ds l) := TRANSFORM
    mkRow := TRANSFORM({unsigned id}, SELF.id := l.id1;);
    SELF.cnt := COUNT(NOFOLD(DEDUP(NOFOLD(DATASET(ROW(mkRow))),id)));
    SELF := l;
END;

p := PROJECT(ds, t(LEFT));
             
cnt := COUNT(NOFOLD(p)(cnt=1));

OUTPUT(cnt = config.simpleRecordCount DIV scale);
