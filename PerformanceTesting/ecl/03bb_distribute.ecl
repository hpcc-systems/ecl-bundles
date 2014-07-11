//class=memory
//class=distribute

import perform.config, perform.format, perform.files;
import Std.System.ThorLib;

ds := files.generateSimple();

d := distribute(ds, ThorLib.node());

output(COUNT(NOFOLD(d)) = config.simpleRecordCount);
