//class=memory
//class=hashaggregate

import $ as suite;
import suite.perform.config;
import suite.perform.format;
import suite.perform.files;

ds := files.generateSimple();
unsigned8 numBins := 64;

t := TABLE(ds, { id3 % numBins, cnt := COUNT(group) }, id3 % numBins, FEW);

output(COUNT(NOFOLD(t)) = numBins);
