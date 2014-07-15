//class=memory
//class=join
//class=smartjoin

import perform.tests;

j := tests.join(1);
output(COUNT(NOFOLD(j.joinLocalSmart)) = j.numExpected);
