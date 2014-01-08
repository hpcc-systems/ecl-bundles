import perform.config, perform.format, perform.files;

ds := files.diskPadded(false);

OUTPUT(COUNT(NOFOLD(ds)) = config.simpleRecordCount);
