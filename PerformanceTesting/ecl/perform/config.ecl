/*
This file contains all the constants that configure how many records will be generated.  It is archived if the results are saved.
*/
export config := MODULE
    export smokeTest := FALSE; // If True, some of the tests use much smaller data
    export memoryPerSlave := 0x100000000; // 4Gb is fairly standard memory configuration
    export numSlaves := IF(__PLATFORM__='roxie', 1, CLUSTERSIZE);
    export indexScale := 1;
    export SplitWidth := 16;  // Number of ways the splitter/appending tests divide
    export recordAllocSize := 64; // Actual memory used by one of the records
    export simpleRecordCount := (memoryPerSlave * numSlaves) / recordAllocSize / 2;  // Aim for enough records to ensure memory is not quite filled.
end;
