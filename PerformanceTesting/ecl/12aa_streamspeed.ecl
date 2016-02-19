//class=memory
//class=quick
//class=create

//version hintNumStrands=1,hintBlockSize=512,hintWriteWork=4,hintReadWork=0,hintIsOrdered=true
//version hintNumStrands=6,hintBlockSize=512,hintWriteWork=4,hintReadWork=0,hintIsOrdered=true
//version hintNumStrands=6,hintBlockSize=512,hintWriteWork=4,hintReadWork=0,hintIsOrdered=false

//version hintNumStrands=1,hintBlockSize=512,hintWriteWork=16,hintReadWork=0,hintIsOrdered=true
//version hintNumStrands=6,hintBlockSize=512,hintWriteWork=16,hintReadWork=0,hintIsOrdered=true
//version hintNumStrands=6,hintBlockSize=512,hintWriteWork=16,hintReadWork=0,hintIsOrdered=false

//version hintNumStrands=1,hintBlockSize=512,hintWriteWork=64,hintReadWork=0,hintIsOrdered=true
//version hintNumStrands=6,hintBlockSize=512,hintWriteWork=64,hintReadWork=0,hintIsOrdered=true
//version hintNumStrands=6,hintBlockSize=512,hintWriteWork=64,hintReadWork=0,hintIsOrdered=false

//xversion hintNumStrands=8,hintBlockSize=8096,hintWriteWork=4,hintReadWork=0,hintIsOrdered=true
//xversion hintNumStrands=8,hintBlockSize=8096,hintWriteWork=4,hintReadWork=0,hintIsOrdered=false

//xversion hintNumStrands=1,hintBlockSize=1,hintWriteWork=1
//xversion hintNumStrands=1,hintBlockSize=1,hintWriteWork=4
//xversion hintNumStrands=1,hintBlockSize=1,hintWriteWork=8
//xversion hintNumStrands=1,hintBlockSize=1,hintWriteWork=16
//xversion hintNumStrands=1,hintBlockSize=1,hintWriteWork=32

//xversion hintNumStrands=8,hintBlockSize=1,hintWriteWork=32,hintReadWork=0

//xversion hintNumStrands=8,hintBlockSize=512,hintWriteWork=1,hintReadWork=0
//xversion hintNumStrands=8,hintBlockSize=512,hintWriteWork=4,hintReadWork=0
//xversion hintNumStrands=8,hintBlockSize=512,hintWriteWork=8,hintReadWork=0
//xversion hintNumStrands=8,hintBlockSize=512,hintWriteWork=16,hintReadWork=0
//xversion hintNumStrands=8,hintBlockSize=512,hintWriteWork=32,hintReadWork=0

//xversion hintNumStrands=8,hintBlockSize=512,hintWriteWork=1,hintReadWork=1
//xversion hintNumStrands=8,hintBlockSize=512,hintWriteWork=4,hintReadWork=1
//xversion hintNumStrands=8,hintBlockSize=512,hintWriteWork=8,hintReadWork=1
//xversion hintNumStrands=8,hintBlockSize=512,hintWriteWork=16,hintReadWork=1
//xversion hintNumStrands=8,hintBlockSize=512,hintWriteWork=32,hintReadWork=1

//xversion hintNumStrands=8,hintBlockSize=512,hintWriteWork=1,hintReadWork=8
//xversion hintNumStrands=8,hintBlockSize=512,hintWriteWork=4,hintReadWork=8
//xversion hintNumStrands=8,hintBlockSize=512,hintWriteWork=8,hintReadWork=8
//xversion hintNumStrands=8,hintBlockSize=512,hintWriteWork=16,hintReadWork=8
//xversion hintNumStrands=8,hintBlockSize=512,hintWriteWork=32,hintReadWork=8

//xversion hintNumStrands=8,hintBlockSize=512,hintWriteWork=1,hintReadWork=32
//xversion hintNumStrands=8,hintBlockSize=512,hintWriteWork=4,hintReadWork=32
//xversion hintNumStrands=8,hintBlockSize=512,hintWriteWork=8,hintReadWork=32
//xversion hintNumStrands=8,hintBlockSize=512,hintWriteWork=16,hintReadWork=32
//xversion hintNumStrands=8,hintBlockSize=512,hintWriteWork=32,hintReadWork=32

//xversion hintNumStrands=8,hintBlockSize=512,hintWriteWork=1,hintReadWork=128
//xversion hintNumStrands=8,hintBlockSize=512,hintWriteWork=4,hintReadWork=128
//xversion hintNumStrands=8,hintBlockSize=512,hintWriteWork=8,hintReadWork=128
//xversion hintNumStrands=8,hintBlockSize=512,hintWriteWork=16,hintReadWork=128
//xversion hintNumStrands=8,hintBlockSize=512,hintWriteWork=32,hintReadWork=128

//xversion hintNumStrands=1,hintBlockSize=1

//xversion hintNumStrands=2,hintBlockSize=1
//xversion hintNumStrands=4,hintBlockSize=1
//xversion hintNumStrands=6,hintBlockSize=1
//xversion hintNumStrands=8,hintBlockSize=1
//xversion hintNumStrands=16,hintBlockSize=1

//xversion hintNumStrands=2,hintBlockSize=128
//xversion hintNumStrands=4,hintBlockSize=128
//xversion hintNumStrands=6,hintBlockSize=128
//xversion hintNumStrands=8,hintBlockSize=128
//xversion hintNumStrands=16,hintBlockSize=128

//xversion hintNumStrands=2,hintBlockSize=512
//xversion hintNumStrands=4,hintBlockSize=512
//xversion hintNumStrands=6,hintBlockSize=512
//xversion hintNumStrands=8,hintBlockSize=512
//xversion hintNumStrands=16,hintBlockSize=512

//xversion hintNumStrands=2,hintBlockSize=2048
//xversion hintNumStrands=4,hintBlockSize=2048
//xversion hintNumStrands=6,hintBlockSize=2048
//xversion hintNumStrands=8,hintBlockSize=2048
//xversion hintNumStrands=16,hintBlockSize=2048

//xversion hintNumStrands=2,hintBlockSize=8096
//xversion hintNumStrands=4,hintBlockSize=8096
//xversion hintNumStrands=6,hintBlockSize=8096
//xversion hintNumStrands=8,hintBlockSize=8096
//xversion hintNumStrands=16,hintBlockSize=8096

import ^ as root;
import $ as suite;
import suite.perform.config;
import suite.perform.files;

hintNumStrands := #IFDEFINED(root.hintNumStrands, 8);
hintBlockSize := #IFDEFINED(root.hintBlockSize, 1024);
hintIsOrdered := #IFDEFINED(root.hintIsOrdered, false);
writeWork := #IFDEFINED(root.hintWriteWork, 4);
readWork := #IFDEFINED(root.hintReadWork, 0);

numRecords := 200000000;

unsigned8 performWork(unsigned8 value, unsigned iter) := BEGINC++
    #option pure
    for (unsigned i=0; i < iter; i++)
        value = rtlHash64Data(sizeof(value), &value, value);
    return value;
ENDC++;

{ unsigned8 id } createSimple(unsigned8 c) := TRANSFORM
    SELF.id := performWork(c, writeWork);
END;

ds  := DATASET(numRecords, createSimple(COUNTER), LOCAL, PARALLEL(hintNumStrands),ORDERED(hintIsOrdered),HINT(strandBlockSize(hintBlockSize)));

readDs := NOFOLD(ds)(performWork(id, readWork) * NOFOLD(0) = 0);
cnt := COUNT(NOFOLD(readDs));

OUTPUT(cnt = numRecords * CLUSTERSIZE);
