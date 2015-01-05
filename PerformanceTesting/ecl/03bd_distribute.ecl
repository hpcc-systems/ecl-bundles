//class=memory
//class=distribute

import $ as suite;
import suite.perform.config;
import suite.perform.format;
import suite.perform.files;
import Std.System.ThorLib;

ds := files.generateSimple();

d := distribute(ds, ThorLib.node()+CLUSTERSIZE DIV 2);

output(COUNT(NOFOLD(d)) = config.simpleRecordCount);
