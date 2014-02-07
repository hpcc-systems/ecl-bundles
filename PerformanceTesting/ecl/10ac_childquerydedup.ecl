import perform.config;
import perform.format;
import perform.files;
import perform.util;

unsigned scale := IF(config.smokeTest, 0x1000, 0x10);
ds := files.generateSimpleScaled(0, scale);

resultRec := RECORD
    RECORDOF(ds);
    unsigned cnt;
END;

resultRec t(ds l) := TRANSFORM
    mkRows := DATASET(40, TRANSFORM({unsigned id}, SELF.id := l.id1 + COUNTER;));
    SELF.cnt := COUNT(NOFOLD(DEDUP(NOFOLD(mkRows),id)));
    SELF := l;
END;

p := PROJECT(ds, t(LEFT));
             
cnt := COUNT(NOFOLD(p)(cnt=40));

OUTPUT(cnt = config.simpleRecordCount DIV scale);
