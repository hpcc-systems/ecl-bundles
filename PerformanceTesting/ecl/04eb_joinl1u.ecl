//class=memory
//class=parallel
//class=join

import perform.tests;

j := tests.join(1);
output(COUNT(NOFOLD(j.joinLocalUnordered)) = j.numExpected);
