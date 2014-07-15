//nohthor
//noroxie

//class=memory
//class=join
//class=smartjoin

import perform.tests;

j := tests.smartjoin(3, 0, 1);  // total records = 3x what will fit on one node
output(COUNT(NOFOLD(j.joinSmartInnerParallel)) = j.numExpected);
