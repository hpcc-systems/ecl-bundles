import perform.config, perform.format, perform.files;
import Std.System.ThorLib;

ds := files.generateSimple();

d := distribute(ds, ThorLib.node()+CLUSTERSIZE DIV 2);

output(COUNT(NOFOLD(d)) = config.simpleRecordCount);
