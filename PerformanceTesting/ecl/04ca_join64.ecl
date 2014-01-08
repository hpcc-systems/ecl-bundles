import $ as perform;
import perform.tests;

j := tests.join(64);
output(COUNT(NOFOLD(j.joinNormal)) = j.numExpected);
