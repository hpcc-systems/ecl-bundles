//class=memory
//class=sort

//xversion algo='quicksort'
//xversion algo='parquicksort'
//xversion algo='mergesort'
//xversion algo='parmergesort'
//xversion algo='heapsort'
//xversion algo='tbbstableqsort'

import ^ as root;
import $ as suite;
import suite.perform.config;
import suite.perform.format;
import suite.perform.files;

//version hintNumStrands=0,algo='parmergesort'
//version hintNumStrands=2,algo='parmergesort'
//version hintNumStrands=4,algo='parmergesort'
//version hintNumStrands=6,algo='parmergesort'
//version hintNumStrands=8,algo='parmergesort'
//version hintNumStrands=4,algo='parmergesort',hintBlockSize=128
//version hintNumStrands=4,algo='parmergesort',hintBlockSize=1024
//version hintNumStrands=4,algo='parmergesort',hintBlockSize=2048

algo := #IFDEFINED(root.algo, 'quicksort');
hintNumStrands := #IFDEFINED(root.hintNumStrands, 8);
hintBlockSize := #IFDEFINED(root.hintBlockSize, 512);

ds := files.generateSimple();

s1 := sort(ds, id3, local, stable(algo));
output(COUNT(NOFOLD(s1)) = config.simpleRecordCount);
