//class=child
//class=index
//class=indexread

import $ as suite;
import suite.perform.config;
import suite.perform.format;
import suite.perform.files;
import suite.perform.util;

unsigned scale := IF(config.smokeTest, 0x10000, 0x100);
ds := files.generateSimpleScaled(0, scale);

resultRec := RECORD
    RECORDOF(ds);
    dataset(RECORDOF(files.manyIndex321)) matches;
END;

resultRec t(ds l) := TRANSFORM
    //Stepped read-only one matching record
    SELF.matches := SORTED(STEPPED(files.manyIndex321(
            id3a = util.byte(l.id3, 0) AND 
            id3b = util.byte(l.id3, 1) AND 
            id3c = util.byte(l.id3, 2)), id2), id2, ASSERT);
    SELF := l;
END;

p := PROJECT(ds, t(LEFT));
             
cnt := COUNT(NOFOLD(p));

OUTPUT(cnt = config.simpleRecordCount DIV scale);
