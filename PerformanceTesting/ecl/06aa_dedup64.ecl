//class=memory
//class=hashdedup

import $ as suite;
import suite.perform.config;
import suite.perform.format;
import suite.perform.files;

ds := files.generateSimple();
unsigned8 numBins := 64;

t := DEDUP(ds, id3 % numBins, ALL, MANY);

output(COUNT(NOFOLD(t)) = numBins);
