//class=memory
//class=sort
//version algo='parquicksort'
//version algo='parmergesort'
//version algo='tbbstableqsort',nohthor

import ^ as root;
algo := #IFDEFINED(root.algo, 'quicksort');

import $ as suite;
import suite.perform.config;
import suite.perform.format;
import suite.perform.files;

ds := files.generateSimple();

//Check sort speed if already reverse sorted 
s1 := sort(NOFOLD(ds), -id1, local, stable(algo));
output(COUNT(NOFOLD(s1)) = config.simpleRecordCount);
