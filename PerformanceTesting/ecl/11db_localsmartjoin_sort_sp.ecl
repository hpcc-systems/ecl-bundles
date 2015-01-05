//nohthor
//noroxie

//class=memory
//class=join
//class=smartjoin

import $ as suite;
import suite.perform.tests;

j := tests.smartjoin(4, 0, 1);  // total records  = 4x what will fit on a single node
output(COUNT(NOFOLD(j.joinLocalUnorderedSmartInner)) = j.numExpected);
