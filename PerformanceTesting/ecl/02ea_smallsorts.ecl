//class=memory
//class=sort


//version algo='quicksort',nothor
//version algo='parquicksort'
//version algo='mergesort',nothor
//version algo='parmergesort'
//version algo='heapsort',nothor

import ^ as root;
algo := #IFDEFINED(root.algo, 'quicksort');
 
idRecord := RECORD
    UNSIGNED id;
END;

idRecords := DATASET(20000, TRANSFORM(idRecord, SELF.id := COUNTER-1));

idRecord t(idRecord l) := TRANSFORM
    ids := DATASET(l.id, TRANSFORM(idRecord, SELF.id := HASH64(COUNTER)));
    s := SORT(ids, id, STABLE(algo));
    check := SORTED(NOFOLD(s), id, ASSERT);
    c := COUNT(NOFOLD(check));
    SELF.id := l.id - c;
END;

p := PROJECT(idRecords, t(LEFT));
OUTPUT(p(id != 0));
