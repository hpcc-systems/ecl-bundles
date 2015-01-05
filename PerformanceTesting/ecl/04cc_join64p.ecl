//class=memory
//class=parallel
//class=join

import $ as suite;
import suite.perform.tests;

j := tests.join(64);
output(COUNT(NOFOLD(j.joinParallel)) = j.numExpected);
