//nohthor
//noroxie

//class=memory
//class=join
//class=smartjoin

import $ as suite;
import suite.perform.tests;

j := tests.smartjoin(0.25, 0, 1);  // total records  = 1/4 of what will fit on a single node
//This should return no records - if it does the output will gives some clues to what went wrong
output(NOFOLD(j.joinSmartLeftOnly), {id1, src := (id1 * 24) DIV j.numInputRows, dest := HASH32(id1-1) % 24 });
