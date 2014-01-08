import std.System.Workunit AS Wu;
import Std.System.Job;

wuRecord := RECORD
    STRING wuid;
    STRING job;
END;

gatheredRecord := RECORD(wuRecord)
    DATASET(wu.StatisticRecord) statistics;
    DATASET(wu.StatisticRecord) timingsAsStats;
END;

StatisticRecord := wu.StatisticRecord AND NOT [maxValue] OR wuRecord;

resultRec := RECORD
    unsigned minValue;
    unsigned maxValue;
    unsigned aveValue;
    unsigned medValue;
    STRING8 date;
    STRING job;
    STRING statname;
END;

generateSummary(string searchCluster) := FUNCTION

   completedWorkUnits := Wu.WorkunitList('', cluster := searchCluster, state := 'completed');

   regressSuiteWu := completedWorkunits(REGEXFIND('^[0-9]+[a-z][a-z]_', job));

   RETURN PROJECT(regressSuiteWu, TRANSFORM(wuRecord, SELF.wuid := TRIM(LEFT.wuid); SELF.job := TRIM(LEFT.job)));
END;

gatherStatistics(DATASET(wuRecord) wus) := FUNCTION

    gatheredRecord addStats(wuRecord l) := TRANSFORM
        stats := Wu.WorkunitStatistics(l.wuid);
        
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

expandStatistics(DATASET(gatheredRecord) wus) := FUNCTION

    StatisticRecord t(wuRecord l, wu.StatisticRecord r) := TRANSFORM
        SELF := l;
        SELF := r;
    END;

    RETURN NORMALIZE(wus, LEFT.statistics, t(LEFT, RIGHT));
END;

allWorkunits := generateSummary(job.target());
allStatistics := NOTHOR(gatherStatistics(allWorkunits));
expandedStatistics := expandStatistics(allStatistics);

interestingStats := ['Process', 'roxiehwm'];

filteredStatistics := expandedStatistics(name in ALL);

groupedByJobDate := GROUP(filteredStatistics, job, wuid[1..9], name, ALL);

sortByDuration := SORT(groupedByJobDate, value);

resultRec combineResults(StatisticRecord l, DATASET(StatisticRecord) statistics) := TRANSFORM
    SELF := l;
    SELF.date := l.wuid[2..9];
    SELF.statName := l.name;
    SELF.minValue := MIN(statistics, value);
    SELF.maxValue := MAX(statistics, value);
    SELF.aveValue := AVE(statistics, value);
    SELF.medValue := statistics[(COUNT(statistics)+1) DIV 2].value;
    SELF := [];
END;

summarised := ROLLUP(sortByDuration, GROUP, combineResults(LEFT, ROWS(LEFT)));

interesting := summarised(maxValue != 0);

output(interesting,NAMED('Interesting'));

uniqueDates := SORT(TABLE(dedup(interesting, date, HASH), { STRING8 x := date }), x);
uniqueJobs := SORT(TABLE(dedup(interesting, job, HASH), { STRING y := job }), y);
uniqueStats := SORT(TABLE(dedup(interesting, statName, HASH), { STRING stat := statName }), stat);

xValues := ROW(TRANSFORM({ STRING8 x }, SELF.x := '')) & uniqueDates;
yValues := ROW(TRANSFORM({ STRING y }, SELF.y := '')) & uniqueJobs;

crossProduct := SORT(JOIN(xValues, yValues, true, ALL), y, x);

xyValueRec := { STRING8 x; STRING y; UNICODE text };

createValueTable(dataset(resultRec) ds, real scale, unsigned numPlaces) := FUNCTION 
    xyValueRec extractResult(crossProduct l, resultRec r) := TRANSFORM
        SELF := l;
        SELF.text := MAP(l.x = '' => l.y,
                          l.y = '' => l.x,
                          IF(r.date = '', '', REALFORMAT((r.aveValue * scale), numPlaces+7, numPlaces)));
    END;
    
    RETURN JOIN(crossProduct, ds, LEFT.x = RIGHT.date AND LEFT.y = RIGHT.job, extractResult(LEFT, RIGHT), LEFT OUTER, MANY LOOKUP);
END;


createHtmlTable(DATASET(xyValueRec) values) := FUNCTION

    import CellFormatter.HTML;

    xyValueRec toHTML(xyValueRec l) := TRANSFORM
        SELF.text := IF(l.y = '', HTML.TableHeader(l.text), HTML.TableCell(l.text));
        SELF := l;
    END;

    concatRows1(GROUPED DATASET(xyValueRec) Values) :=
        AGGREGATE(values, xyValueRec, TRANSFORM(xyValueRec, SELF.text := RIGHT.text + LEFT.text; SELF := LEFT));

    concatRows2(DATASET(xyValueRec) Values) :=
        AGGREGATE(values, xyValueRec, TRANSFORM(xyValueRec, SELF.text := RIGHT.text + LEFT.text; SELF := LEFT));

    HtmlCells := PROJECT(values, toHTML(LEFT));

    byRow := concatRows1(GROUP(HtmlCells, y));

    AddRows := PROJECT(byRow, TRANSFORM(xyValueRec, SELF.text := HTML.TableRow(LEFT.text); SELF := LEFT));

    byAll := concatRows2(AddRows);

    RETURN TABLE(byAll, { UNICODE text__html := HTML.Table(text, TRUE); });
END;

valuesProcess := createValueTable(interesting(statName = 'Process'), 0.000000001, 3);
output(createHtmlTable(valuesProcess),NAMED('Time_Trends'));

valuesMemory := createValueTable(interesting(statName = 'roxiehwm'), 0.000001, 3);
output(createHtmlTable(valuesMemory),NAMED('Memory_Trends'));

output(uniqueDates,,NAMED('Dates'));
output(uniqueJobs, NAMED('Jobs'));
output(dedup(expandedStatistics, name, ALL), { name }, NAMED('Available_Statistics'));
