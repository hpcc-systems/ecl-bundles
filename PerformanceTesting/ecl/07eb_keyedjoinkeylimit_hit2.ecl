//class=index
//class=keyedjoin
//class=stress

import $ as suite;
import suite.perform.config;
import suite.perform.format;
import suite.perform.files;
import suite.perform.util;

unsigned scale := IF(config.smokeTest, 0x10000, 0x100);
ds := files.generateSimpleScaled(0, scale);

j := JOIN(ds, files.manyIndex321,
            WILD(RIGHT.id3a) AND 
            KEYED(RIGHT.id3b = util.byte(LEFT.id3, 1)) AND 
            KEYED(RIGHT.id3c = util.byte(LEFT.id3, 2)) AND
            KEYED(RIGHT.id3d = util.byte(LEFT.id3, 3)), 
            LIMIT(1, SKIP, COUNT)); 
cnt := COUNT(NOFOLD(j));

OUTPUT(cnt < config.simpleRecordCount DIV scale);
