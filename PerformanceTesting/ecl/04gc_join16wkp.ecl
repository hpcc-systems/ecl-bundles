//class=memory
//class=parallel
//class=join

//currently neither hthor or roxie support parallel joins, so not much point testing theem
//nohthor
//noroxie

//version hintProjectWork=0
//version hintProjectWork=4
//version hintProjectWork=16
//version hintProjectWork=64
//version hintProjectWork=256

import ^ as root;

projectWork := #IFDEFINED(root.hintProjectWork, 4);

import $ as suite;
import suite.perform.tests;

j := tests.join(16);
output(COUNT(NOFOLD(j.joinParallelWork(projectWork))) = j.numExpected);
