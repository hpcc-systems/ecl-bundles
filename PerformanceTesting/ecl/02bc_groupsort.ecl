//class=memory
//class=sort

import perform.config, perform.format, perform.files;

ds := files.generateSimple();

g := GROUP(ds, id2 & NOFOLD(0), LOCAL);
s := sort(g, id3);

output(COUNT(NOFOLD(s)) = config.simpleRecordCount);
