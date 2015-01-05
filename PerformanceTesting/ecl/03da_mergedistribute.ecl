//class=memory
//class=distribute

import $ as suite;
import suite.perform.config;
import suite.perform.format;
import suite.perform.files;

ds := files.generateSimple();

s := sort(ds, id3, local);

m := DISTRIBUTE(s, HASH(id3), MERGE(id3));
output(COUNT(NOFOLD(m)) = config.simpleRecordCount);
