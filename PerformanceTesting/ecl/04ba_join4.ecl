import $ as perform;
import perform.tests;

j := tests.join(4);
output(COUNT(NOFOLD(j.joinNormal)) = j.numExpected);
