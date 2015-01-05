//class=child
//class=index
//class=indexread

import $ as suite;
import suite.perform.config;
import suite.perform.format;
import suite.perform.files;
import suite.perform.util;

unsigned scale := IF(config.smokeTest, 0x100000, 0x1000);
ds := files.generateSimpleScaled(0, scale);

resultRec := RECORD
    RECORDOF(ds);
    dataset(RECORDOF(files.manyIndex123)) matches;
END;

resultRec t(ds l) := TRANSFORM
    //Stepped read-only one matching record
    SELF.matches := SORTED(STEPPED(files.manyIndex123(
            id1a = util.byte(l.id1, 0) AND 
            id1b = util.byte(l.id1, 1) AND 
            id1c = util.byte(l.id1, 2) AND 
            id1d = util.byte(l.id1, 3) AND 
            id1e = util.byte(l.id1, 4) AND 
            id1f = util.byte(l.id1, 5) AND 
            id1g = util.byte(l.id1, 6)), id2), id2, ASSERT);
    SELF := l;
END;

p := PROJECT(ds, t(LEFT));
             
cnt := COUNT(NOFOLD(p)(COUNT(matches)=IF(id1 <= 255, 255, 256)));

OUTPUT(cnt = config.simpleRecordCount DIV scale);
