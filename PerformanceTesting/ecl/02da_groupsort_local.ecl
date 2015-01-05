//class=memory
//class=sort

import $ as suite;
import suite.perform.config;
import suite.perform.format;
import suite.perform.files;

ds := files.generateSimple();

s := sort(ds, id1, id3, local);

output(COUNT(NOFOLD(s)) = config.simpleRecordCount);
