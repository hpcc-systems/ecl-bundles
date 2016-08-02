//class=memory
//class=sort

import ^ as root;

import $ as suite;
import suite.perform.config;
import suite.perform.format;
import suite.perform.files;

ds := files.generateSimple();

s1 := sort(NOFOLD(ds)((id1 % 2) = 1), id3, local);
output(COUNT(NOFOLD(s1)) = config.simpleRecordCount/2);
