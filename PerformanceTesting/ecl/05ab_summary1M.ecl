//class=memory
//class=hashaggregate

import $ as suite;
import suite.perform.config;
import suite.perform.format;
import suite.perform.files;

ds := files.generateSimple();
unsigned8 numBins := 1000000;

t := TABLE(ds, { id3 % numBins, cnt := COUNT(group) }, id3 % numBins);
numResults := COUNT(NOFOLD(t));

//It is hard to know what this number is likely to be:
//  If simpleRecordCount << numBins it is likely to be ~simpleRecordCount.
//  If simpleRecordCount >> numBins it is likely to be ~numBins.
output(numResults BETWEEN 1 AND numBins);
