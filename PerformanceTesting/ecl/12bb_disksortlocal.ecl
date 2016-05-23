//class=disk
//class=sort


//version hintNumStrands=0
//version hintNumStrands=2
//version hintNumStrands=4
//version hintNumStrands=6
//version hintNumStrands=8

import ^ as root;
import $ as suite;
import suite.perform.config;
import suite.perform.format;
import suite.perform.files;

hintNumStrands := #IFDEFINED(root.hintNumStrands, 4);
hintBlockSize := #IFDEFINED(root.hintBlockSize, 64);

ds := files.diskSimple(false);

s := sort(ds, id3, local);

output(s,,files.simpleName+'_uncompressed_02aa',OVERWRITE, HINT(numStrands(hintNumStrands),strandBlockSize(4000)));
