//class=memory
//class=parallel
//class=join

import $ as perform;
import perform.tests;

j := tests.join(64);
output(COUNT(NOFOLD(j.joinParallel)) = j.numExpected);
