import perform.config, perform.format, perform.files;

ds := files.diskSimple(true);

OUTPUT(COUNT(NOFOLD(ds)) = config.simpleRecordCount);
