//class=memory
//class=hashdedup

import $ as suite;
import suite.perform.config;
import suite.perform.format;
import suite.perform.files;

ds := files.generateSimple();

t := DEDUP(ds, id3, HASH);

output(COUNT(NOFOLD(t)) = config.simpleRecordCount);
