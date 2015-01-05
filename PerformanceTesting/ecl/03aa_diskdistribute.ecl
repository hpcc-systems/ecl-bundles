//class=disk
//class=distribute

import $ as suite;
import suite.perform.config;
import suite.perform.format;
import suite.perform.files;

ds := files.diskSimple(false);

d := distribute(ds, hash32(id3));

output(d,,files.simpleName+'_uncompressed_03aa',OVERWRITE);
