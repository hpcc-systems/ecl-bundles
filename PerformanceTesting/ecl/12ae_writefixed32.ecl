//class=disk
//class=diskwrite
//class=setup

//version hintNumStrands=0
//version hintNumStrands=4,hintBlockSize=1000
//version hintNumStrands=2,hintBlockSize=10000
//version hintNumStrands=4,hintBlockSize=10000
//version hintNumStrands=6,hintBlockSize=10000
//version hintNumStrands=4,hintBlockSize=40000
//version hintNumStrands=4,hintBlockSize=100000

import ^ as root;
import $ as suite;
import suite.perform.config;
import suite.perform.format;
import suite.perform.files;

hintNumStrands := #IFDEFINED(root.hintNumStrands, 4);
hintBlockSize := #IFDEFINED(root.hintBlockSize, 10000);

ds := DATASET(config.simpleRecordCount, format.createSimple(COUNTER), DISTRIBUTED);

OUTPUT(ds,,files.simpleName+'_uncompressed',overwrite, HINT(numStrands(hintNumStrands),strandBlockSize(hintBlockSize)));
