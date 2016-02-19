//class=memory
//class=sort
//version algo='quicksort'
//version algo='parquicksort'
//version algo='mergesort'
//version algo='parmergesort'
//version algo='heapsort'
//version algo='tbbstableqsort',nohthor

import ^ as root;
algo := #IFDEFINED(root.algo, 'parmergesort');

import $ as suite;
import suite.perform.config;
import suite.perform.format;
import suite.perform.files;

ds := files.generateSimple();

s1 := sort(ds, id3, local, stable(algo));
output(COUNT(NOFOLD(s1)) = config.simpleRecordCount);
