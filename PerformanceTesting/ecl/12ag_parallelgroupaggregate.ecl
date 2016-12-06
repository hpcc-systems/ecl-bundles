//class=memory
//class=quick
//class=create

//Single stranded - base line comparison
//version hintNumStrands=1,hintBlockSize=500,hintProjectWork=0,hintIsOrdered=false
//version hintNumStrands=1,hintBlockSize=500,hintProjectWork=4,hintIsOrdered=false
//version hintNumStrands=1,hintBlockSize=500,hintProjectWork=16,hintIsOrdered=false
//version hintNumStrands=1,hintBlockSize=500,hintProjectWork=64,hintIsOrdered=false
//version hintNumStrands=1,hintBlockSize=500,hintProjectWork=256,hintIsOrdered=false

//Stranded - strands=4, all combinations of source project and aggregate executed in parallel
//version hintNumStrands=4,hintBlockSize=500,hintProjectWork=0,hintIsOrdered=false
//version hintNumStrands=4,hintBlockSize=500,hintProjectWork=4,hintIsOrdered=false
//version hintNumStrands=4,hintBlockSize=500,hintProjectWork=16,hintIsOrdered=false
//version hintNumStrands=4,hintBlockSize=500,hintProjectWork=64,hintIsOrdered=false
//version hintNumStrands=4,hintBlockSize=500,hintProjectWork=256,hintIsOrdered=false

//version hintNumStrands=16,hintBlockSize=500,hintProjectWork=0,hintIsOrdered=false
//version hintNumStrands=16,hintBlockSize=500,hintProjectWork=4,hintIsOrdered=false
//version hintNumStrands=16,hintBlockSize=500,hintProjectWork=16,hintIsOrdered=false
//version hintNumStrands=16,hintBlockSize=500,hintProjectWork=64,hintIsOrdered=false
//version hintNumStrands=16,hintBlockSize=500,hintProjectWork=256,hintIsOrdered=false

import ^ as root;
import $ as suite;
import suite.perform.config;
import suite.perform.files;

hintNumStrands := #IFDEFINED(root.hintNumStrands, 4);
hintBlockSize := #IFDEFINED(root.hintBlockSize, 500);
hintIsOrdered := #IFDEFINED(root.hintIsOrdered, false);
projectWork := #IFDEFINED(root.hintProjectWork, 16);
parallelSource := #IFDEFINED(root.hintParallelSource, false);
parallelCount := #IFDEFINED(root.hintParallelCount, true);

numRecords := 200000*32;

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

whichGroup(unsigned i) := MAP(i<2 => 1,
                              i<6 => 2,
                              i<13 => 3,
                              4);

gr := GROUP(ds, whichGroup((id-1) & 15));

r2 t(r1 l) := TRANSFORM, SKIP(l.id % 5 = 6)
    SELF.id := l.id;
    SELF.val := performWork(l.id, projectWork);
END;

p := PROJECT(NOFOLD(gr), t(LEFT), PARALLEL(hintNumStrands),ORDERED(hintIsOrdered),HINT(strandBlockSize(hintBlockSize)));

agg := TABLE(NOFOLD(p), { cnt := COUNT(GROUP) }, PARALLEL(hintNumStrands));

agg2 := NOFOLD(TABLE(NOFOLD(agg), { unsigned cnt := COUNT(GROUP), sumcnt := SUM(GROUP, cnt*cnt) }));

OUTPUT(agg2[1].cnt - CLUSTERSIZE * numRecords DIV 4);// * 1 * 4 DIV 5);
//OUTPUT(CHOOSEN(agg, 30));
OUTPUT(agg2[1].sumcnt - (numRecords DIV 16) * (4+16+49+9) * CLUSTERSIZE );
