//nohthor
//noroxie

//class=memory
//class=join
//class=smartjoin

import $ as suite;
import suite.perform.tests;

j := tests.smartjoin(0, 0.25, 1);  // total records = 1/4 of what will fit on all nodes
output(COUNT(NOFOLD(j.joinSmartInnerParallel)) = j.numExpected);
