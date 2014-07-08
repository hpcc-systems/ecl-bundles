//class=disk
//class=sort

import perform.config, perform.format, perform.files;

ds := files.diskSimple(false);

s := sort(ds, id3, local);

output(s,,files.simpleName+'_uncompressed_02aa',OVERWRITE);
