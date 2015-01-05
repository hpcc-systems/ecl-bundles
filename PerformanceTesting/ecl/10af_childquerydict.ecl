//class=child
//class=memory

import $ as suite;
import suite.perform.config;
import suite.perform.format;
import suite.perform.files;
import suite.perform.util;

#option ('globalAutoHoist', false);

//MORE: More records would be better, but that currently generates complains about the spill being too big...
unsigned scale := IF(config.smokeTest, 0x1000, 0x100);
ds := files.generateSimpleScaled(0, scale);

resultRec := RECORD
    RECORDOF(ds);
    unsigned cnt;
END;

myDictionary := dictionary(dataset(config.simpleRecordCount DIV scale, TRANSFORM({unsigned id1 => unsigned id2}, SELF.id1 := COUNTER; SELF.id2 := HASH64(COUNTER))));

resultRec t(ds l) := TRANSFORM
    mkRow := TRANSFORM({unsigned id}, SELF.id := l.id2 - myDictionary[l.id1].id2;);
    SELF.cnt := COUNT(NOFOLD(DEDUP(NOFOLD(DATASET(ROW(mkRow))),id))(id = 0));
    SELF := l;
END;

p := PROJECT(ds, t(LEFT));
             
cnt := COUNT(NOFOLD(p)(cnt=1));

OUTPUT(cnt = config.simpleRecordCount DIV scale);
