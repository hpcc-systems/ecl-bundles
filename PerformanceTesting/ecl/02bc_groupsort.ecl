//class=memory
//class=sort
//version groupSize=1
//version groupSize=2
//version groupSize=4
//version groupSize=8
//version groupSize=16
//version groupSize=64
//version groupSize=1024
//version groupSize=65536
//version groupSize=0x100000

import ^ as root;
import $ as suite;
import suite.perform.config;
import suite.perform.format;
import suite.perform.files;

groupSize := #IFDEFINED(root.groupSize, 4);

ds := files.generateSimple();

g := GROUP(ds, id1 DIV groupSize, LOCAL);
s := sort(g, id3);

output(COUNT(NOFOLD(s)) = config.simpleRecordCount);
