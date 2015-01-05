//class=memory
//class=join
//class=smartjoin

import $ as suite;
import suite.perform.tests;

j := tests.join(1);
output(COUNT(NOFOLD(j.joinSmart)) = j.numExpected);
