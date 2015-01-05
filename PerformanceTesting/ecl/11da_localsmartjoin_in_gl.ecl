//nohthor
//noroxie

//class=memory
//class=join
//class=smartjoin

import $ as suite;
import suite.perform.tests;

j := tests.smartjoin(0.25, 0, 1);  // total records  = 1/4 of what will fit on a single node
output(COUNT(NOFOLD(j.joinLocalUnorderedSmartInner)) = j.numExpected);
