//class=memory
//class=sort
//version algo='quicksort'
//version algo='parquicksort'
//version algo='mergesort'
//version algo='parmergesort'
//version algo='heapsort'
//version algo='insertionsort'

import ^ as root;
algo := #IFDEFINED(root.algo, 'quicksort');

import $ as suite;
import suite.perform.config;
import suite.perform.format;
import suite.perform.files;

ds := files.generateSimple();

s := sort(ds, id3, local, stable(algo));

output(COUNT(NOFOLD(s)) = config.simpleRecordCount);
