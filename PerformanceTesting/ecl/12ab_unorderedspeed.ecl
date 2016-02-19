//class=memory
//class=quick
//class=create
//noroxie - parallel join helpers not currently implemented in roxie

//version hintWriteWork=0,hintReadWork=0,hintNewHelper=false
//version hintWriteWork=16,hintReadWork=0,hintNewHelper=false
//version hintWriteWork=64,hintReadWork=0,hintNewHelper=false
//version hintWriteWork=256,hintReadWork=0,hintNewHelper=false
//version hintWriteWork=512,hintReadWork=0,hintNewHelper=false
//version hintWriteWork=1024,hintReadWork=0,hintNewHelper=false

//version hintWriteWork=0,hintReadWork=0,hintNewHelper=true
//version hintWriteWork=16,hintReadWork=0,hintNewHelper=true
//version hintWriteWork=64,hintReadWork=0,hintNewHelper=true
//version hintWriteWork=256,hintReadWork=0,hintNewHelper=true
//version hintWriteWork=512,hintReadWork=0,hintNewHelper=true
//version hintWriteWork=1024,hintReadWork=0,hintNewHelper=true

import ^ as root;
import $ as suite;

writeWork := #IFDEFINED(root.hintWriteWork, 0);
readWork := #IFDEFINED(root.hintReadWork, 0);
useNewHelper := #IFDEFINED(root.hintNewHelper, true);

numRecords := 0x100000;

unsigned8 performWork(unsigned8 value, unsigned iter) := BEGINC++
    #option pure
    for (unsigned i=0; i < iter; i++)
        value = rtlHash64Data(sizeof(value), &value, value);
    return value;
ENDC++;

r := { unsigned8 id };

r createSimple(unsigned8 c) := TRANSFORM
    SELF.id := c-1;
END;

dsLeft  := DATASET(numRecords, createSimple(COUNTER), LOCAL);
dsRight  := DATASET(numRecords+NOFOLD(0), createSimple(COUNTER), LOCAL);

r t(r l) := TRANSFORM
    SELF.id := performWork(l.id, writeWork);
END;

joinDs := JOIN(dsLeft, dsRight, LEFT.id DIV 32 = RIGHT.id DIV 32, t(LEFT), STREAMED, UNORDERED, LOCAL,HINT(newJoinHelper(useNewHelper),strandBlockSize(1000)));

readDs := NOFOLD(joinDs)(performWork(id, readWork) * NOFOLD(0) = 0);
cnt := COUNT(NOFOLD(readDs));

OUTPUT(cnt = numRecords*32*CLUSTERSIZE);
