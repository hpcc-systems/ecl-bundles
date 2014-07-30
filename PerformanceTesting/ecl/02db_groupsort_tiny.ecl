//class=memory
//class=sort

import perform.config, perform.format, perform.files;

ds := files.generateSimple();

s1 := sorted(ds, id1);
s := sort(s1, id1, id3, local); // should convert to a grouped sort

output(COUNT(NOFOLD(s)) = config.simpleRecordCount);
