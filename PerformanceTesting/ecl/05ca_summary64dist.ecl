//class=memory
//class=hashaggregate

import perform.config, perform.format, perform.files;

ds := files.generateSimple();
unsigned8 numBins := 64;

d := DISTRIBUTE(ds, id3 % numBins);
t := TABLE(NOFOLD(d), { id3 % numBins, cnt := COUNT(group) }, id3 % numBins);
output(COUNT(NOFOLD(t)) = numBins);
