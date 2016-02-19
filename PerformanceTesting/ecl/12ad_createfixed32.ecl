//class=memory
//class=quick
//class=create
//version hintNumStrands=2,hintBlockSize=100,hintStrandOrdered=true

//version hintNumStrands=1,hintBlockSize=1,hintStrandOrdered=true

//version hintNumStrands=2,hintBlockSize=1,hintStrandOrdered=true
//version hintNumStrands=4,hintBlockSize=1,hintStrandOrdered=true
//version hintNumStrands=6,hintBlockSize=1,hintStrandOrdered=true
//version hintNumStrands=8,hintBlockSize=1,hintStrandOrdered=true
//version hintNumStrands=16,hintBlockSize=1,hintStrandOrdered=true

//version hintNumStrands=2,hintBlockSize=100,hintStrandOrdered=true
//version hintNumStrands=4,hintBlockSize=100,hintStrandOrdered=true
//version hintNumStrands=6,hintBlockSize=100,hintStrandOrdered=true
//version hintNumStrands=8,hintBlockSize=100,hintStrandOrdered=true
//version hintNumStrands=16,hintBlockSize=100,hintStrandOrdered=true

//version hintNumStrands=2,hintBlockSize=500,hintStrandOrdered=true
//version hintNumStrands=4,hintBlockSize=500,hintStrandOrdered=true
//version hintNumStrands=6,hintBlockSize=500,hintStrandOrdered=true
//version hintNumStrands=8,hintBlockSize=500,hintStrandOrdered=true
//version hintNumStrands=16,hintBlockSize=500,hintStrandOrdered=true

//version hintNumStrands=2,hintBlockSize=500,hintStrandOrdered=false
//version hintNumStrands=4,hintBlockSize=500,hintStrandOrdered=false
//version hintNumStrands=6,hintBlockSize=500,hintStrandOrdered=false
//version hintNumStrands=8,hintBlockSize=500,hintStrandOrdered=false
//version hintNumStrands=16,hintBlockSize=500,hintStrandOrdered=false

//version hintNumStrands=2,hintBlockSize=2000,hintStrandOrdered=true
//version hintNumStrands=4,hintBlockSize=2000,hintStrandOrdered=true
//version hintNumStrands=6,hintBlockSize=2000,hintStrandOrdered=true
//version hintNumStrands=8,hintBlockSize=2000,hintStrandOrdered=true
//version hintNumStrands=16,hintBlockSize=2000,hintStrandOrdered=true

//version hintNumStrands=2,hintBlockSize=8000,hintStrandOrdered=true
//version hintNumStrands=4,hintBlockSize=8000,hintStrandOrdered=true
//version hintNumStrands=6,hintBlockSize=8000,hintStrandOrdered=true
//version hintNumStrands=8,hintBlockSize=8000,hintStrandOrdered=true
//version hintNumStrands=16,hintBlockSize=8000,hintStrandOrdered=true

import ^ as root;
import $ as suite;
import suite.perform.config;
import suite.perform.files;
import suite.perform.format;

hintNumStrands := #IFDEFINED(root.hintNumStrands, 8);
hintBlockSize := #IFDEFINED(root.hintBlockSize, 128);
hintStrandOrdered := #IFDEFINED(root.hintStrandOrdered, false);

ds  := DATASET(config.simpleRecordCount, format.createSimple(COUNTER),DISTRIBUTED,PARALLEL(hintNumStrands),ORDERED(hintStrandOrdered),HINT(strandBlockSize(hintBlockSize)));

cnt := COUNT(NOFOLD(ds));

OUTPUT(cnt = config.simpleRecordCount);
