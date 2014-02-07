import perform.config, perform.format, perform.files;
import Std.System.ThorLib;

ds := files.generateSimple();

d := distribute(ds, ThorLib.node()+1);

output(COUNT(NOFOLD(d)) = config.simpleRecordCount);
