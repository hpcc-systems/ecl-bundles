import perform.config, perform.format, perform.files;

ds := files.generateSimple();

d := DISTRIBUTE(ds, id3);
t := DEDUP(NOFOLD(d), id3, ALL, MANY);
output(COUNT(NOFOLD(t)) = config.simpleRecordCount);
