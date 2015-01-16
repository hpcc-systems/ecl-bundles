//class=memory
//class=sort
//nokey

import Std.System.Debug;

unsigned startTime := Debug.msTick() : independent;

//version scale=1
//version scale=2
//version scale=4
//version scale=8
//version scale=16
//xversion scale=24

import ^ as root;
scale := #IFDEFINED(root.scale, 1);

import $ as suite;
import suite.perform.config, suite.perform.format, suite.perform.files;

ds := files.generateN(0, scale*0x40000000/48);

s := sort(ds, id3, local);

output(COUNT(NOFOLD(s)));
output(Debug.msTick() - startTime);
