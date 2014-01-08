import $ as perform;
import perform.tests;

j := tests.join(64);
output(COUNT(NOFOLD(j.joinLookup)) = j.numExpected);
