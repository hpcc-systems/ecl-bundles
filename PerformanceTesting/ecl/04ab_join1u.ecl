import perform.tests;

j := tests.join(1);
output(COUNT(NOFOLD(j.joinUnordered)) = j.numExpected);
