//class=index
//class=keyedjoin
//class=stress

import $ as suite;
import suite.perform.config;
import suite.perform.format;
import suite.perform.files;
import suite.perform.util;

unsigned scale := IF(config.smokeTest, 0x1000, 0x10);
ds := files.generateSimpleScaled(0, scale);

j := JOIN(ds, files.manyIndex321,
            RIGHT.id3a = util.byte(LEFT.id3, 0) AND 
            RIGHT.id3b = util.byte(LEFT.id3, 1) AND 
            RIGHT.id3c = util.byte(LEFT.id3, 2) AND 
            RIGHT.id3d = util.byte(LEFT.id3, 3) AND 
            RIGHT.id3e = util.byte(LEFT.id3, 4) AND 
            RIGHT.id3f = util.byte(LEFT.id3, 5) AND 
            RIGHT.id3g = util.byte(LEFT.id3, 6) AND 
            RIGHT.id3h = util.byte(LEFT.id3, 7),LIMIT(0)); 
cnt := COUNT(NOFOLD(j));

OUTPUT(cnt = config.simpleRecordCount DIV scale);
