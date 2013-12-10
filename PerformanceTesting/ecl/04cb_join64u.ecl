import $ as perform;
import perform.tests;

j := tests.join(64);
output(COUNT(NOFOLD(j.joinUnordered)) = j.numExpected);
