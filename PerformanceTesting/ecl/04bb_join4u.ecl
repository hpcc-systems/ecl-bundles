//class=memory
//class=parallel
//class=join

import $ as suite;
import suite.perform.tests;

j := tests.join(4);
output(COUNT(NOFOLD(j.joinUnordered)) = j.numExpected);
