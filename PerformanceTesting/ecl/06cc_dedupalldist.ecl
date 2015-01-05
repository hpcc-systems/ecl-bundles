//class=memory
//class=hashdedup

import $ as suite;
import suite.perform.config;
import suite.perform.format;
import suite.perform.files;

ds := files.generateSimple();

d := DISTRIBUTE(ds, id3);
t := DEDUP(NOFOLD(d), id3, ALL, MANY);
output(COUNT(NOFOLD(t)) = config.simpleRecordCount);
