//class=memory
//class=sort

import $ as suite;
import suite.perform.config;
import suite.perform.format;
import suite.perform.files;

ds := files.generateSimple();

doSort(dataset(format.simpleRec) ds, unsigned scale) := FUNCTION
    gr := GROUP(NOFOLD(ds), id1 DIV scale,LOCAL);
    s := SORT(gr, HASH32(id1));
    RETURN NOFOLD(GROUP(s));
END;

s2 := doSort(ds, 2);
s4 := doSort(s2, 4);
s8 := doSort(s4, 8);
s15 := doSort(s8, 15);

output(COUNT(NOFOLD(s15)) = config.simpleRecordCount);
