//class=memory
//class=quick
//class=create

//The first set of versions are used to create a vaguely representative set of timings that can be compared between versions

//version hintNumStrands=1,hintBlockSize=500,hintProjectWork=4,hintParallelSource=false,hintParallelCount=false,hintIsOrdered=false

//version hintNumStrands=1,hintBlockSize=500,hintProjectWork=64,hintParallelSource=false,hintParallelCount=false,hintIsOrdered=false

//version hintNumStrands=4,hintBlockSize=500,hintProjectWork=4,hintParallelSource=false,hintParallelCount=false,hintIsOrdered=false

//version hintNumStrands=4,hintBlockSize=500,hintProjectWork=64,hintParallelSource=false,hintParallelCount=false,hintIsOrdered=false

//version hintNumStrands=4,hintBlockSize=500,hintProjectWork=4,hintParallelSource=true,hintParallelCount=true,hintIsOrdered=true

//version hintNumStrands=16,hintBlockSize=500,hintProjectWork=64,hintParallelSource=true,hintParallelCount=true,hintIsOrdered=true

//version hintNumStrands=16,hintBlockSize=500,hintProjectWork=4,hintParallelSource=false,hintParallelCount=false,hintIsOrdered=false

//version hintNumStrands=16,hintBlockSize=500,hintProjectWork=64,hintParallelSource=false,hintParallelCount=false,hintIsOrdered=false

//version hintNumStrands=16,hintBlockSize=500,hintProjectWork=4,hintParallelSource=true,hintParallelCount=true,hintIsOrdered=true

//version hintNumStrands=16,hintBlockSize=500,hintProjectWork=64,hintParallelSource=true,hintParallelCount=true,hintIsOrdered=true

//The following tests are primarily here to compare the different varieties within a version

//Single stranded - base line comparison
//xversion hintNumStrands=1,hintBlockSize=500,hintProjectWork=0,hintParallelSource=false,hintParallelCount=false,hintIsOrdered=false
//xversion hintNumStrands=1,hintBlockSize=500,hintProjectWork=4,hintParallelSource=false,hintParallelCount=false,hintIsOrdered=false
//xversion hintNumStrands=1,hintBlockSize=500,hintProjectWork=16,hintParallelSource=false,hintParallelCount=false,hintIsOrdered=false
//xversion hintNumStrands=1,hintBlockSize=500,hintProjectWork=64,hintParallelSource=false,hintParallelCount=false,hintIsOrdered=false
//xversion hintNumStrands=1,hintBlockSize=500,hintProjectWork=256,hintParallelSource=false,hintParallelCount=false,hintIsOrdered=false

//Stranded - work=0, all combinations of source project and aggregate executed in parallel
//xversion hintNumStrands=4,hintBlockSize=500,hintProjectWork=0,hintParallelSource=false,hintParallelCount=false,hintIsOrdered=false
//xversion hintNumStrands=4,hintBlockSize=500,hintProjectWork=0,hintParallelSource=false,hintParallelCount=false,hintIsOrdered=true
//xversion hintNumStrands=4,hintBlockSize=500,hintProjectWork=0,hintParallelSource=true,hintParallelCount=false,hintIsOrdered=false
//xversion hintNumStrands=4,hintBlockSize=500,hintProjectWork=0,hintParallelSource=true,hintParallelCount=false,hintIsOrdered=true
//xversion hintNumStrands=4,hintBlockSize=500,hintProjectWork=0,hintParallelSource=false,hintParallelCount=true,hintIsOrdered=false
//xversion hintNumStrands=4,hintBlockSize=500,hintProjectWork=0,hintParallelSource=false,hintParallelCount=true,hintIsOrdered=true
//xversion hintNumStrands=4,hintBlockSize=500,hintProjectWork=0,hintParallelSource=true,hintParallelCount=true,hintIsOrdered=false
//xversion hintNumStrands=4,hintBlockSize=500,hintProjectWork=0,hintParallelSource=true,hintParallelCount=true,hintIsOrdered=true

//Stranded - work=4, all combinations of source project and aggregate executed in parallel
//xversion hintNumStrands=4,hintBlockSize=500,hintProjectWork=4,hintParallelSource=false,hintParallelCount=false,hintIsOrdered=false
//xversion hintNumStrands=4,hintBlockSize=500,hintProjectWork=4,hintParallelSource=false,hintParallelCount=false,hintIsOrdered=true
//xversion hintNumStrands=4,hintBlockSize=500,hintProjectWork=4,hintParallelSource=true,hintParallelCount=false,hintIsOrdered=false
//xversion hintNumStrands=4,hintBlockSize=500,hintProjectWork=4,hintParallelSource=true,hintParallelCount=false,hintIsOrdered=true
//xversion hintNumStrands=4,hintBlockSize=500,hintProjectWork=4,hintParallelSource=false,hintParallelCount=true,hintIsOrdered=false
//xversion hintNumStrands=4,hintBlockSize=500,hintProjectWork=4,hintParallelSource=false,hintParallelCount=true,hintIsOrdered=true
//xversion hintNumStrands=4,hintBlockSize=500,hintProjectWork=4,hintParallelSource=true,hintParallelCount=true,hintIsOrdered=false
//xversion hintNumStrands=4,hintBlockSize=500,hintProjectWork=4,hintParallelSource=true,hintParallelCount=true,hintIsOrdered=true

//Stranded - work=16, all combinations of source project and aggregate executed in parallel
//xversion hintNumStrands=4,hintBlockSize=500,hintProjectWork=16,hintParallelSource=false,hintParallelCount=false,hintIsOrdered=false
//xversion hintNumStrands=4,hintBlockSize=500,hintProjectWork=16,hintParallelSource=false,hintParallelCount=false,hintIsOrdered=true
//xversion hintNumStrands=4,hintBlockSize=500,hintProjectWork=16,hintParallelSource=true,hintParallelCount=false,hintIsOrdered=false
//xversion hintNumStrands=4,hintBlockSize=500,hintProjectWork=16,hintParallelSource=true,hintParallelCount=false,hintIsOrdered=true
//xversion hintNumStrands=4,hintBlockSize=500,hintProjectWork=16,hintParallelSource=false,hintParallelCount=true,hintIsOrdered=false
//xversion hintNumStrands=4,hintBlockSize=500,hintProjectWork=16,hintParallelSource=false,hintParallelCount=true,hintIsOrdered=true
//xversion hintNumStrands=4,hintBlockSize=500,hintProjectWork=16,hintParallelSource=true,hintParallelCount=true,hintIsOrdered=false
//xversion hintNumStrands=4,hintBlockSize=500,hintProjectWork=16,hintParallelSource=true,hintParallelCount=true,hintIsOrdered=true

//Stranded - work=64, all combinations of source project and aggregate executed in parallel
//xversion hintNumStrands=4,hintBlockSize=500,hintProjectWork=64,hintParallelSource=false,hintParallelCount=false,hintIsOrdered=false
//xversion hintNumStrands=4,hintBlockSize=500,hintProjectWork=64,hintParallelSource=false,hintParallelCount=false,hintIsOrdered=true
//xversion hintNumStrands=4,hintBlockSize=500,hintProjectWork=64,hintParallelSource=true,hintParallelCount=false,hintIsOrdered=false
//xversion hintNumStrands=4,hintBlockSize=500,hintProjectWork=64,hintParallelSource=true,hintParallelCount=false,hintIsOrdered=true
//xversion hintNumStrands=4,hintBlockSize=500,hintProjectWork=64,hintParallelSource=false,hintParallelCount=true,hintIsOrdered=false
//xversion hintNumStrands=4,hintBlockSize=500,hintProjectWork=64,hintParallelSource=false,hintParallelCount=true,hintIsOrdered=true
//xversion hintNumStrands=4,hintBlockSize=500,hintProjectWork=64,hintParallelSource=true,hintParallelCount=true,hintIsOrdered=false
//xversion hintNumStrands=4,hintBlockSize=500,hintProjectWork=64,hintParallelSource=true,hintParallelCount=true,hintIsOrdered=true

//Stranded - work=256, all combinations of source project and aggregate executed in parallel
//xversion hintNumStrands=4,hintBlockSize=500,hintProjectWork=256,hintParallelSource=false,hintParallelCount=false,hintIsOrdered=false
//xversion hintNumStrands=4,hintBlockSize=500,hintProjectWork=256,hintParallelSource=false,hintParallelCount=false,hintIsOrdered=true
//xversion hintNumStrands=4,hintBlockSize=500,hintProjectWork=256,hintParallelSource=true,hintParallelCount=false,hintIsOrdered=false
//xversion hintNumStrands=4,hintBlockSize=500,hintProjectWork=256,hintParallelSource=true,hintParallelCount=false,hintIsOrdered=true
//xversion hintNumStrands=4,hintBlockSize=500,hintProjectWork=256,hintParallelSource=false,hintParallelCount=true,hintIsOrdered=false
//xversion hintNumStrands=4,hintBlockSize=500,hintProjectWork=256,hintParallelSource=false,hintParallelCount=true,hintIsOrdered=true
//xversion hintNumStrands=4,hintBlockSize=500,hintProjectWork=256,hintParallelSource=true,hintParallelCount=true,hintIsOrdered=false
//xversion hintNumStrands=4,hintBlockSize=500,hintProjectWork=256,hintParallelSource=true,hintParallelCount=true,hintIsOrdered=true

//Different amounts of work for large numbers of strands
//Stranded - work=4, all combinations of source project and aggregate executed in parallel
//xversion hintNumStrands=16,hintBlockSize=500,hintProjectWork=4,hintParallelSource=false,hintParallelCount=false,hintIsOrdered=false
//xversion hintNumStrands=16,hintBlockSize=500,hintProjectWork=4,hintParallelSource=false,hintParallelCount=false,hintIsOrdered=true
//xversion hintNumStrands=16,hintBlockSize=500,hintProjectWork=4,hintParallelSource=true,hintParallelCount=false,hintIsOrdered=false
//xversion hintNumStrands=16,hintBlockSize=500,hintProjectWork=4,hintParallelSource=true,hintParallelCount=false,hintIsOrdered=true
//xversion hintNumStrands=16,hintBlockSize=500,hintProjectWork=4,hintParallelSource=false,hintParallelCount=true,hintIsOrdered=false
//xversion hintNumStrands=16,hintBlockSize=500,hintProjectWork=4,hintParallelSource=false,hintParallelCount=true,hintIsOrdered=true
//xversion hintNumStrands=16,hintBlockSize=500,hintProjectWork=4,hintParallelSource=true,hintParallelCount=true,hintIsOrdered=false
//xversion hintNumStrands=16,hintBlockSize=500,hintProjectWork=4,hintParallelSource=true,hintParallelCount=true,hintIsOrdered=true

//Stranded - work=256, all combinations of source project and aggregate executed in parallel
//xversion hintNumStrands=16,hintBlockSize=500,hintProjectWork=256,hintParallelSource=false,hintParallelCount=false,hintIsOrdered=false
//xversion hintNumStrands=16,hintBlockSize=500,hintProjectWork=256,hintParallelSource=false,hintParallelCount=false,hintIsOrdered=true
//xversion hintNumStrands=16,hintBlockSize=500,hintProjectWork=256,hintParallelSource=true,hintParallelCount=false,hintIsOrdered=false
//xversion hintNumStrands=16,hintBlockSize=500,hintProjectWork=256,hintParallelSource=true,hintParallelCount=false,hintIsOrdered=true
//xversion hintNumStrands=16,hintBlockSize=500,hintProjectWork=256,hintParallelSource=false,hintParallelCount=true,hintIsOrdered=false
//xversion hintNumStrands=16,hintBlockSize=500,hintProjectWork=256,hintParallelSource=false,hintParallelCount=true,hintIsOrdered=true
//xversion hintNumStrands=16,hintBlockSize=500,hintProjectWork=256,hintParallelSource=true,hintParallelCount=true,hintIsOrdered=false
//xversion hintNumStrands=16,hintBlockSize=500,hintProjectWork=256,hintParallelSource=true,hintParallelCount=true,hintIsOrdered=true

import ^ as root;
import $ as suite;
import suite.perform.config;
import suite.perform.files;

hintNumStrands := #IFDEFINED(root.hintNumStrands, 16);
hintBlockSize := #IFDEFINED(root.hintBlockSize, 500);
hintIsOrdered := #IFDEFINED(root.hintIsOrdered, false);
projectWork := #IFDEFINED(root.hintProjectWork, 4);
parallelSource := #IFDEFINED(root.hintParallelSource, false);
parallelCount := #IFDEFINED(root.hintParallelCount, false);

numRecords := 50000000;

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

ds := DATASET(numRecords, createSimple(COUNTER), LOCAL, PARALLEL(IF(parallelSource,0,1)));

r2 t(r1 l) := TRANSFORM, SKIP(l.id % 5 = 6)
    SELF.id := l.id;
    SELF.val := performWork(l.id, projectWork);
END;

p := PROJECT(NOFOLD(ds), t(LEFT), PARALLEL(hintNumStrands),ORDERED(hintIsOrdered),HINT(strandBlockSize(hintBlockSize)));

s := IF(hintIsOrdered, SORTED(NOFOLD(p), id, ASSERT), p);

cnt := NOFOLD(COUNT(NOFOLD(p), PARALLEL(IF(parallelCount,0,1))));

OUTPUT(cnt - numRecords * CLUSTERSIZE);// * 1 * 4 DIV 5);
