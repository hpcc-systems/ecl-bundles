//class=child
//class=index
//class=indexread
//class=stress

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
            //No filter on id3a 
            id3b = util.byte(l.id3, 1) AND 
            id3c = util.byte(l.id3, 2) AND 
            id3d = util.byte(l.id3, 3) AND 
            id3e = util.byte(l.id3, 4) AND 
            id3f = util.byte(l.id3, 5) AND 
            id3g = util.byte(l.id3, 6) AND 
            id3h = util.byte(l.id3, 7)), id2), id2, ASSERT);
    SELF := l;
END : onwarning(4515, ignore);   // id3a is deliberately (and painfully) skipped;

p := PROJECT(ds, t(LEFT));
             
cnt := COUNT(NOFOLD(p)(COUNT(matches) BETWEEN 1 AND 2));      // Note, number of matches is still likely to be 1 from probability, very unlikely to be more than 2

OUTPUT(cnt = config.simpleRecordCount DIV scale);
