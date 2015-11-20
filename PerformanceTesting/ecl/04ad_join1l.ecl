//class=memory
//class=join

import $ as suite;
import suite.perform.tests;

j := tests.join(1);
output(COUNT(NOFOLD(j.joinLookup)) = j.numExpected);
