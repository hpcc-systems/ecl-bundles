//class=memory
//class=parallel
//class=join

import $ as suite;
import suite.perform.tests;

j := tests.join(1);
output(COUNT(NOFOLD(j.joinLocalParallel)) = j.numExpected);
