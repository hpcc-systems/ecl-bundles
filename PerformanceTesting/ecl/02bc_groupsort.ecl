//class=memory
//class=sort

import $ as suite;
import suite.perform.config;
import suite.perform.format;
import suite.perform.files;

ds := files.generateSimple();

g := GROUP(ds, id2 & NOFOLD(0), LOCAL);
s := sort(g, id3);

output(COUNT(NOFOLD(s)) = config.simpleRecordCount);
