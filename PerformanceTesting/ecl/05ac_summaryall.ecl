//class=memory
//class=hashaggregate

import $ as suite;
import suite.perform.config;
import suite.perform.format;
import suite.perform.files;

ds := files.generateSimple();

t := TABLE(ds, { id3, cnt := COUNT(group) }, id3);

output(COUNT(NOFOLD(t)) = config.simpleRecordCount);
