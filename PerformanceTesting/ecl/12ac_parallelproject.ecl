//class=memory
//class=quick
//class=create

//version hintNumStrands=1,hintBlockSize=500,hintProjectWork=4,hintIsOrdered=true
//version hintNumStrands=1,hintBlockSize=500,hintProjectWork=16,hintIsOrdered=true
//version hintNumStrands=1,hintBlockSize=500,hintProjectWork=64,hintIsOrdered=true
//version hintNumStrands=4,hintBlockSize=500,hintProjectWork=4,hintIsOrdered=true
//version hintNumStrands=4,hintBlockSize=500,hintProjectWork=16,hintIsOrdered=true
//version hintNumStrands=4,hintBlockSize=500,hintProjectWork=64,hintIsOrdered=true
//version hintNumStrands=2,hintBlockSize=500,hintProjectWork=256,hintIsOrdered=true
//version hintNumStrands=4,hintBlockSize=500,hintProjectWork=256,hintIsOrdered=true
//version hintNumStrands=6,hintBlockSize=500,hintProjectWork=256,hintIsOrdered=true
//version hintNumStrands=8,hintBlockSize=500,hintProjectWork=256,hintIsOrdered=true
//version hintNumStrands=4,hintBlockSize=500,hintProjectWork=4,hintIsOrdered=false
//version hintNumStrands=4,hintBlockSize=500,hintProjectWork=16,hintIsOrdered=false
//version hintNumStrands=4,hintBlockSize=500,hintProjectWork=64,hintIsOrdered=false

import ^ as root;
import $ as suite;
import suite.perform.config;
import suite.perform.files;

hintNumStrands := #IFDEFINED(root.hintNumStrands, 0);
hintBlockSize := #IFDEFINED(root.hintBlockSize, 1024);
hintIsOrdered := #IFDEFINED(root.hintIsOrdered, true);
projectWork := #IFDEFINED(root.hintProjectWork, 0);

numRecords := 20000000;

unsigned8 performWork(unsigned8 value, unsigned iter) := BEGINC++
    #option pure
    for (unsigned i=0; i < iter; i++)
        value = rtlHash64Data(sizeof(value), &value, value);
    return value;
ENDC++;

r1 := { unsigned8 id };
r2 := { unsigned8 id, unsigned8 val; };

r1 createSimple(unsigned8 c) := TRANSFORM
    SELF.id := c;
END;

ds := DATASET(numRecords, createSimple(COUNTER), LOCAL);

r2 t(r1 l) := TRANSFORM, SKIP(l.id % 5 = 0)
    SELF.id := l.id;
    SELF.val := performWork(l.id, projectWork);
END;

p := PROJECT(NOFOLD(ds), t(LEFT), HINT(numStrands(hintNumStrands),strandBlockSize(hintBlockSize),strandOrdered(hintIsOrdered)));

s := IF(hintIsOrdered, SORTED(NOFOLD(p), id, ASSERT), p);

cnt := COUNT(NOFOLD(s));

OUTPUT(cnt = numRecords * CLUSTERSIZE * 4 DIV 5);
