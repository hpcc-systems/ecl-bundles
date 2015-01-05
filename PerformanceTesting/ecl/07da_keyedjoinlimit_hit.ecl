//class=index
//class=keyedjoin

import $ as suite;
import suite.perform.config;
import suite.perform.format;
import suite.perform.files;
import suite.perform.util;

unsigned scale := IF(config.smokeTest, 0x10000, 0x100);
ds := files.generateSimpleScaled(0, scale);

j := JOIN(ds, files.manyIndex321,
            RIGHT.id3a = util.byte(LEFT.id3, 0) AND 
            RIGHT.id3b = util.byte(LEFT.id3, 1) AND 
            RIGHT.id3c = util.byte(LEFT.id3, 2),
            LIMIT(1, SKIP)); 
cnt := COUNT(NOFOLD(j));

OUTPUT(cnt < config.simpleRecordCount DIV scale);
