//class=memory
//class=sort


//version algo='quicksort',numrows=2000,nothor
//version algo='parquicksort',numrows=2000,nothor
//version algo='mergesort',numrows=1000,nothor
//version algo='mergesort',numrows=2000,nothor
//version algo='mergesort',numrows=4000,nothor
//version algo='mergesort',numrows=6000,nothor
//version algo='mergesort',numrows=10000,nothor
//version algo='parmergesort',numrows=1000
//version algo='parmergesort',numrows=2000
//version algo='parmergesort',numrows=4000
//version algo='parmergesort',numrows=6000
//version algo='parmergesort',numrows=10000

import ^ as root;
algo := #IFDEFINED(root.algo, 'quicksort');
numRows := #IFDEFINED(root.numrows, 100);
 
idRecord := RECORD
    UNSIGNED id;
END;

import Std.System.Debug;

idRecords := DATASET(10000, TRANSFORM(idRecord, SELF.id := COUNTER-1));

idRecord t(idRecord l) := TRANSFORM
    ids := DATASET(numRows + (l.id * NOFOLD(0)), TRANSFORM(idRecord, SELF.id := HASH64(COUNTER)));
    s := SORT(ids, id, STABLE(algo));
    check := SORTED(NOFOLD(s), id, ASSERT);
    c := COUNT(NOFOLD(check));
    SELF.id := numrows - c;
END;

p := PROJECT(idRecords, t(LEFT));
OUTPUT(p(id != 0));

