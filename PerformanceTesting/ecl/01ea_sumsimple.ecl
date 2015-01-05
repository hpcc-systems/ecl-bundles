//class=disk
//class=quick
//class=diskread

import $ as suite;
import suite.perform.config, suite.perform.format, suite.perform.files;

ds := files.diskSimple(false);

expectedSum := (config.simpleRecordCount * (config.simpleRecordCount + 1)) DIV 2;
OUTPUT(SUM(ds,id1) = expectedSum); // Allow input dataset to be projected and optimized
