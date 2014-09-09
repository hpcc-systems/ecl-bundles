//class=summary

import std.System.Workunit AS Wu;
import Std.System.Job;
import Std.Str;

//nokey - the results from this query are output in the log output

wuRecord := RECORD
    STRING instance;
    STRING wuid;
    STRING job;
END;

gatheredRecord := RECORD(wuRecord)
    DATASET(wu.StatisticRecord) statistics;
    DATASET(wu.StatisticRecord) timingsAsStats;
END;

resultRec := RECORD
    unsigned minValue;
    unsigned maxValue;
    unsigned aveValue;
    unsigned medValue;
    STRING instance;
    STRING job;
    STRING statname;
END;

generateSummary(string searchCluster) := FUNCTION

   completedWorkUnits := Wu.WorkunitList('', cluster := searchCluster, state := 'completed');

   regressSuiteWu := completedWorkunits(REGEXFIND('^[0-9]+[a-z][a-z]_', job));

   wuRecord extractWuInfo(Wu.WorkunitRecord l) := TRANSFORM
        SELF.wuid := TRIM(l.wuid);
        SELF.job := TRIM(l.job[1..Str.Find(l.job, '-')-1]);
        SELF.instance := l.wuid[2..9] + ':' + l.cluster;
   END;

   RETURN PROJECT(regressSuiteWu, extractWuInfo(LEFT));
END;

gatherStatistics(DATASET(wuRecord) wus) := FUNCTION

    gatheredRecord addStats(wuRecord l) := TRANSFORM
        stats := Wu.WorkunitStatistics(l.wuid, false);
        
        wu.StatisticRecord convertTimingToStat(wu.TimingRecord l) := TRANSFORM
            import Std.Str;
            words := Str.SplitWords(l.name, ';');
            SELF.creator := IF(count(words)>1, words[1], '');
            SELF.scope := words[2]; 
            SELF.name := IF(count(words)>1, words[3], l.name);
            SELF.description := l.name;
            SELF.count := l.count;
            SELF.value := l.duration * 1000000;
            SELF.unit := 'ns';
            SELF := [];
        END;
        timingsAsStats := PROJECT(Wu.WorkunitTimings(l.wuid), convertTimingToStat(LEFT));
        
        SELF := l;
        SELF.statistics := stats;
        SELF.timingsAsStats := timingsAsStats;
    END;

    gatheredRecord pickBestStats(gatheredRecord l) := TRANSFORM
        SELF.statistics := IF(EXISTS(l.statistics), l.statistics, l.timingsAsStats);
        SELF.timingsAsStats := [];
        SELF := l;
    END;

    withStats := PROJECT(wus, addStats(LEFT));
    selectStats := PROJECT(withStats, pickBestStats(LEFT));
    RETURN selectStats;
END;

StatisticRecord := RECORD
    string time;
    string mem;
    string job;
END;


expandStatistics(DATASET(gatheredRecord) wus) := FUNCTION

    StatisticRecord t(gatheredRecord l) := TRANSFORM
        SELF.time := REALFORMAT(l.statistics(scope = 'Process' OR name = 'Process')[1].value / 100000000.0, 12, 3) + 's';
        SELF.mem := REALFORMAT(l.statistics(name = 'roxiehwm')[1].value / 1000.0, 10, 3) + 'Mb';
        SELF := l;
    END;

    RETURN PROJECT(wus, t(LEFT));
END;

allWorkunits := NOTHOR(generateSummary(''));
mostRecent := DEDUP(SORT(allWorkUnits, job, -wuid), job) : global(few);
allStatistics := NOTHOR(gatherStatistics(mostRecent));
expandedStatistics := expandStatistics(allStatistics);

output(expandedStatistics);

