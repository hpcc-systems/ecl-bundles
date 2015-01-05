//nohthor
//noroxie

//class=stress
//class=join
//class=smartjoin

import $ as suite;
import suite.perform.tests;

j := tests.smartjoin(0, 4, 1);  // total records  = 4x what will fit on all nodes
output(COUNT(NOFOLD(j.joinSmartInnerParallel)) = j.numExpected);
