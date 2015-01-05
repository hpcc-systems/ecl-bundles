//class=memory
//class=sort

import $ as suite;
import suite.perform.config;
import suite.perform.format;
import suite.perform.files;

ds := files.generateSimple();

s := sort(ds, (unsigned)(log(id3+1) / log(1.0001)), SKEW(1.0)); // generate skewed groups.

output(COUNT(NOFOLD(s)) = config.simpleRecordCount);
