//class=memory
//class=join

import $ as suite;
import suite.perform.tests;

j := tests.join(4096);
output(COUNT(NOFOLD(j.joinNormal)) = j.numExpected);
