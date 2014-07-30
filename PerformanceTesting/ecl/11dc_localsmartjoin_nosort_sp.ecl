//nohthor
//noroxie

//class=memory
//class=join
//class=smartjoin

import perform.tests;

j := tests.smartjoin(4, 0, 1);  // total records  = 4x what will fit on a single node
output(COUNT(NOFOLD(j.joinLocalOrderedSmartInner)) = j.numExpected);
