/* BASED ON GREGORIAN CALENDAR. 2 DIGIT YEARS WILL BE CALCULATED BETWEEN 1950-2049 */
EXPORT Calendar := MODULE
  IMPORT STD;

  EXPORT Bundle := MODULE(Std.BundleBase)
    EXPORT Name          := 'Calendar';
    EXPORT Description   := 'Basic Date functions implementation';
    EXPORT Authors       := ['Omnibuzz'];
    EXPORT License       := 'http://www.apache.org/licenses/LICENSE-2.0';
    EXPORT Copyright     := 'Use, Improve, Extend, Distribute';
    EXPORT DependsOn     := [];
    EXPORT Version       := '1.0.0';
  END; 

  /* EXPORTED TYPES */
  EXPORT Date                             := INTEGER4;
  EXPORT Time                             := INTEGER4;
  EXPORT DateTime                         := INTEGER;
  
  /* OBJECT INTERNALLY USED TO GET THE DATE REPRESENTATION TO FACILITATE INTROSPECTION OF DATE */
  SHARED GetInternalDTRepresentation(DateTime dt)  := MODULE
    EXPORT INTEGER4 DaySecsElapsed                 := (INTEGER4) (dt%86400);
    EXPORT INTEGER4 DaysSince1900                  := (INTEGER4) ((dt-DaySecsElapsed)/86400);
    EXPORT INTEGER4 Date1900Delta                  := 693596; 
    EXPORT INTEGER4 GregorianDayCount              := DaysSince1900 + Date1900Delta;
    EXPORT          GregorianDate                  := STD.Date.ToGregorianYMD(GregorianDayCount);
  END;
  
  /* FUNCTIONS TO CONVERT BETWEEN TYPES */ 
  EXPORT DateTime   DtoDT(Date dt)          := (DateTime)dt*86400;
  EXPORT DateTime   TtoDT(Time t)           := (DateTime)t;
  EXPORT Date       GetDatePart(DateTime dt):= (INTEGER4)(dt/86400);
  EXPORT Time       GetTimePart(DateTime dt):= (INTEGER4)(dt%86400);

  /* Miscellaneous*/
  EXPORT UNSIGNED2   TwoDigitYearCutOff                                               := 49;//Year 50 means 1950, 49 means 2049
  EXPORT BOOLEAN    IsLeapYear(INTEGER2  Year)                                        := STD.Date.IsLeapYear(Year);
  EXPORT UNSIGNED2   ConvertYr2ToYr4(INTEGER2 Yr2)                                    := IF(Yr2 > TwoDigitYearCutOff,1900,2000) + Yr2;
  EXPORT UNSIGNED1   GetMonthNumber(STRING3 MonthName)                                := (UNSIGNED1) (Std.Str.Find('JAN,FEB,MAR,APR,MAY,JUN,JUL,AUG,SEP,OCT,NOV,DEC,',MonthName)/4) + 1;
  EXPORT STRING3     GetMonthName(UNSIGNED1 MonthNumber)                              := CHOOSE(MonthNumber, 'JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC','XXX');
  EXPORT STRING3    GetDayOfWeek(INTEGER4 GregorianDayCount)                          := CHOOSE(GregorianDayCount%7, 'MON','TUE','WED','THU','FRI','SAT','SUN');  
  EXPORT UNSIGNED2  GetDayOfYear(UNSIGNED2 Year,UNSIGNED1 Month,UNSIGNED1 Day)        := CHOOSE(Month+1,0,0,31,59,90,120,151,181,212,243,273,304,334 ) + Day + IF(IsLeapYear(Year) AND Month > 2, 1, 0);
  EXPORT BOOLEAN     IsInvalidDate(UNSIGNED2 Year,UNSIGNED1 Month,UNSIGNED1 Day)      := Year < 1 OR Month < 1 OR Month > 12 OR Day < 1 OR Day > 31;
  EXPORT BOOLEAN     IsInvalidTime(UNSIGNED1 Hour,UNSIGNED1 Minute,UNSIGNED1 Second)  := Hour < 0 OR Hour > 23 OR Minute < 0 OR Minute > 59 OR Second < 0 OR Second > 59;

  /* Functions that can be used to infer datetime */
  EXPORT Date   CreateDFrom(UNSIGNED2 Year,UNSIGNED1 Month,UNSIGNED1 Day) := FUNCTION
    RETURN   STD.Date.DaysSince1900(Year, Month, Day);
  END;

  EXPORT Time    CreateTFrom(UNSIGNED1 Hour,UNSIGNED1 Minute,UNSIGNED1 Second) := FUNCTION
    RETURN   Hour*3600 + Minute*60 + Second;
  END;
  
  EXPORT DateTime CreateDTFrom(UNSIGNED2 Year,UNSIGNED1 Month,UNSIGNED1 Day,UNSIGNED1 Hour,UNSIGNED1 Minute,UNSIGNED1 Second) := FUNCTION
    RETURN  CreateDFrom(Year, Month, Day)*86400 + CreateTFrom(Hour,Minute,Second);
  END;

  EXPORT DateTime CreateDTFromStr(STRING dt,STRING format = 'yyyy-mm-dd hh:mi:ss') := FUNCTION
    UNSIGNED1 Yr4Pos        := STD.Str.Find(format,'yyyy',1); //Extract Year 
    UNSIGNED1 Yr2Pos        := STD.Str.Find(format,'yy',1); //Extract Year 2 - digit

    //Extract Month
    UNSIGNED1 MonthNamePos  := STD.Str.Find(format,'mmm',1);
    UNSIGNED1 MonthPos      := STD.Str.Find(format,'mm',1);

    //Extract Day
    UNSIGNED1 DayPos        := STD.Str.Find(format,'dd',1);

    //Extract Hour
    UNSIGNED1 HourPos       := STD.Str.Find(format,'hh',1);

    //Extract Min
    UNSIGNED1 MinPos        := STD.Str.Find(format,'mi',1);

    //Extract Sec
    UNSIGNED1 SecPos        := STD.Str.Find(format,'ss',1);

    // Calculate the DateParts 
    UNSIGNED2 Year2Digits   := (UNSIGNED2)dt[yr2Pos..yr2Pos + 1];
    UNSIGNED2 Year          := MAP(  Yr4Pos>0 => (UNSIGNED2)dt[yr4Pos..yr4Pos + 3],
                                    Yr2Pos>0 => ConvertYr2ToYr4(Year2Digits),
                                    0);
    UNSIGNED1 Month         := MAP(  MonthNamePos > 0 => GetMonthNumber((STRING3) Dt[MonthNamePos..MonthNamePos + 2]),
                                    MonthPos > 0  => (UNSIGNED1)dt[MonthPos..MonthPos + 1],
                                    0); 
    UNSIGNED1 Day           := IF(DayPos>0,(UNSIGNED1)dt[DayPos..DayPos + 1],0); 

    UNSIGNED1 Hour          := IF(HourPos>0,(UNSIGNED1)dt[HourPos..HourPos + 1],0); 
    UNSIGNED1 Minute        := IF(MinPos>0,(UNSIGNED1)dt[MinPos..MinPos + 1],0); 
    UNSIGNED1 Second        := IF(SecPos>0,(UNSIGNED1)dt[SecPos..SecPos + 1],0);

    InvalidDatePart         := IsInvalidDate(Year,Month,Day);
    InvalidTimePart         := IsInvalidTime(Hour,Minute,Second);
    
    RETURN     MAP(InvalidDatePart AND InvalidTimePart  =>   CreateDTFrom(1900,1,1,0,0,0),
                   InvalidDatePart                      =>   CreateDTFrom(1900,1,1,Hour,Minute,Second),
                   InvalidTimePart                      =>   CreateDTFrom(Year,Month,Day,0,0,0),
                                                             CreateDTFrom(Year,Month,Day,Hour,Minute,Second));
  END;
  
  EXPORT Date CreateDFromStr(STRING d,STRING format = 'yyyy-mm-dd')   := FUNCTION
    RETURN GetDatePart(CreateDTFromStr(d,format));
  END;
  
  EXPORT Time CreateTFromStr(STRING t,STRING format = 'hh:mi:ss')   := FUNCTION
    RETURN GetTimePart(CreateDTFromStr(t,format));
  END;
  
  /* USE THIS MODULE FOR LAZY EVALUATION OF EACH OF THE DATE TIME PARTS.
  IF YOU NEED EVERYTHING TRY USING THE GetDTObject */
  EXPORT IntrospectDT(DateTime dt)          := MODULE
    SHARED            dtInternal          :=   GetInternalDTRepresentation(dt);
    EXPORT INTEGER4   GregorianDayCount   :=   dtInternal.GregorianDayCount;
    EXPORT UNSIGNED2   Year               :=  dtInternal.GregorianDate.Year;
    EXPORT UNSIGNED2   Year2              :=   Year%100;
    EXPORT UNSIGNED1   Month              :=   dtInternal.GregorianDate.Month;
    EXPORT STRING      MonthName          :=   GetMonthName(Month);
    EXPORT STRING      DayOfWeek          :=   GetDayOfWeek(dtInternal.GregorianDayCount);  
    EXPORT UNSIGNED1   Day                :=   dtInternal.GregorianDate.Day;

    EXPORT UNSIGNED1   Second             :=   (UNSIGNED1) dtInternal.DaySecsElapsed%60;
    EXPORT UNSIGNED1   Minute             :=   (UNSIGNED1) ((dtInternal.DaySecsElapsed - Second)%3600)/60;
    EXPORT UNSIGNED1   Hour               :=   (UNSIGNED1) dtInternal.DaySecsElapsed/3600;
    EXPORT UNSIGNED2   DayOfYear          :=   GetDayOfYear(Year,Month,Day);
    EXPORT Date       DatePart            :=   dtInternal.DaysSince1900;
    EXPORT Time      TimePart             :=   dtInternal.DaySecsElapsed;
  END;

  /* USE THIS MODULE FOR LAZY EVALUATION OF EACH OF THE DATE PARTS.
  IF YOU NEED EVERYTHING TRY USING THE GetDObject */
  EXPORT IntrospectD(Date dt)             :=   IntrospectDT(DtoDT(dt));

  /* USE THIS MODULE FOR LAZY EVALUATION OF EACH OF THE TIME PARTS.
  IF YOU NEED EVERYTHING TRY USING THE GetTObject */
  EXPORT IntrospectT(Time t)              :=   IntrospectDT(TtoDT(t));

  EXPORT DTObject := RECORD
    UNSIGNED2   Year;
    UNSIGNED1   Month;
    UNSIGNED1   Day;
    UNSIGNED1   Hour;
    UNSIGNED1   Minute;
    UNSIGNED1   Second;
    UNSIGNED2   Year2;
    STRING    MonthName;
    STRING    DayOfWeek;
    UNSIGNED2   DayOfYear;
    DateTime   dt;
    Date       DatePart;
    Time       TimePart;
    INTEGER3   GregorianDayCount;
  END;

  EXPORT DTObject GetDTRecord(DateTime dt)     := TRANSFORM
    dtInternal              :=    GetInternalDTRepresentation(dt);
    SELF.Year               :=   dtInternal.GregorianDate.Year,
    SELF.Month              :=   dtInternal.GregorianDate.Month,
    SELF.Day                :=   dtInternal.GregorianDate.Day,
    SELF.Hour               :=   (UNSIGNED1) (dtInternal.DaySecsElapsed/3600),
    SELF.Minute             :=   (UNSIGNED1) ((dtInternal.DaySecsElapsed%3600)/60),
    SELF.Second             :=   (UNSIGNED1) dtInternal.DaySecsElapsed%60,
    SELF.Year2              :=   dtInternal.GregorianDate.Year%100,
    SELF.MonthName          :=   GetMonthName(dtInternal.GregorianDate.Month);
    SELF.DayOfWeek          :=   GetDayOfWeek(dtInternal.GregorianDayCount);
    SELF.DayOfYear          :=   GetDayOfYear(dtInternal.GregorianDate.Year,dtInternal.GregorianDate.Month,dtInternal.GregorianDate.Day);
    SELF.dt                 :=   dt,
    SELF.DatePart           :=   dtInternal.DaysSince1900,
    SELF.TimePart           :=   dtInternal.DaySecsElapsed,
    SELF.GregorianDayCount  :=   dtInternal.GregorianDayCount;
  END;  
  
  EXPORT DTObject GetDTObject(DateTime dt)      := FUNCTION
    RETURN ROW(GetDTRecord(dt));
  END;
  
  /* ENUM FOR SPECIFYING DATEPART IN DATEADD AND DATEDIFF FUNCTIONS */
  EXPORT DatePartEnum       := ENUM(UNSIGNED1,Seconds,Minutes,Hours,Days,Months,Years);

  /* This finds the difference between startDate and endDate (startDate-endDate) in terms of the unit specified*/
  EXPORT INTEGER DateDiff(DatePartEnum datePart, DateTime startDate, DateTime endDate) := FUNCTION
    dt1Object         := GetDTObject(startDate);
    dt2Object         := GetDTObject(endDate);
    RETURN CASE(datePart,   DatePartEnum.Years    => dt1Object.Year - dt2Object.Year,
                            DatePartEnum.Months   => dt1Object.Year*12 + dt1Object.Month - (dt2Object.Year*12 + dt2Object.Month),
                            DatePartEnum.Days     => dt1Object.GregorianDayCount - dt2Object.GregorianDayCount,
                            DatePartEnum.Hours    => (INTEGER)(startDate-endDate)/3600,    
                            DatePartEnum.Minutes  => (INTEGER)(startDate-endDate)/60,
                            DatePartEnum.Seconds  => (startDate-endDate),
                            0);
  END;

  EXPORT DateTime DateAdd(DatePartEnum datePart,INTEGER UnitsToAdd, DateTime dt) := FUNCTION
    dtObject         := IntrospectDT(dt);
    RETURN CASE(datePart,   DatePartEnum.Years    => CreateDTFrom(dtObject.Year + UnitsToAdd,
                                                                  dtObject.Month,
                                                                  dtObject.Day,
                                                                  dtObject.Hour,
                                                                  dtObject.Minute,
                                                                  dtObject.Second),
                            DatePartEnum.Months   => CreateDTFrom(dtObject.Year + (INTEGER2) (dtObject.Month + UnitsToAdd)/12,
                                                                  (dtObject.Month + UnitsToAdd)%12,
                                                                  dtObject.Day,
                                                                  dtObject.Hour,
                                                                  dtObject.Minute,
                                                                  dtObject.Second),
                            DatePartEnum.Days     => dt + UnitsToAdd*8640,
                            DatePartEnum.Hours    => dt + UnitsToAdd*3600,    
                            DatePartEnum.Minutes  => dt + UnitsToAdd*60,
                            DatePartEnum.Seconds  => dt + UnitsToAdd,
                            dt);
  END; 

  EXPORT STRING FormatDT(DateTime dt,STRING Format = 'yyyy-mm-dd hh:mi:ss')  := FUNCTION
    dtObject        := GetDTObject(dt);
    YrSubs          := STD.Str.FindReplace(Format,        'yyyy', (STRING)dtObject.Year);
    Yr2Subs         := STD.Str.FindReplace(YrSubs,        'yy'  , (STRING)dtObject.Year2); 
    MonthNameSubs   := STD.Str.FindReplace(Yr2Subs,       'mmm' , dtObject.MonthName);
    MonthSubs       := STD.Str.FindReplace(MonthNameSubs, 'mm'  , ((STRING)(100 + dtObject.Month))[2..]); // This wierd logic is to prepend a zero for single digit month
    DaySubs         := STD.Str.FindReplace(MonthSubs,     'dd'  , ((STRING)(100 + dtObject.Day))[2..]); // I could not find a more optimal way to do it.
    HourSubs        := STD.Str.FindReplace(DaySubs,       'hh'  , ((STRING)(100 + dtObject.Hour))[2..]);
    MinuteSubs      := STD.Str.FindReplace(HourSubs,      'mi'  , ((STRING)(100 + dtObject.Minute))[2..]);
    Final           := STD.Str.FindReplace(MinuteSubs,    'ss'  , ((STRING)(100 + dtObject.Second))[2..]);

    RETURN (STRING)Final;
  END;

  EXPORT STRING FormatD(Date dt, STRING Format = 'yyyy-mm-dd')  := FormatDT(DtoDT(dt),Format);

  EXPORT STRING FormatT(Time t, STRING Format = 'hh:mi:ss')     := FormatDT(TtoDT(t),Format);

  EXPORT UTCNow                   := FUNCTION // Function to get UTC time in yyyy-mm-dd hh:mi:ss format
    STRING19 getUTCNow() := BEGINC++
      #OPTION action
      struct tm gmt;                                // gmtime in "tm" structure
      time_t timeinsecs;                            // variable to store time in secs
      time(&timeinsecs);                            // Get time in sec since Epoch
      gmtime_r(&timeinsecs,&gmt);                   // Convert to UTC time
      strftime(__result, 20, "%F %H:%M:%S", &gmt);  // Formats yyyy-mm-dd hh:mi:ss
    ENDC++;

    RETURN getUTCNow();
  END;

  EXPORT Now                     := FUNCTION // Function to get local time in yyyy-mm-dd hh:mi:ss format
    STRING19 getNow() := BEGINC++
      #OPTION action
      struct tm ltz;                                // local timezone in "tm" structure
      time_t timeinsecs;                            // variable to store time in secs
      time(&timeinsecs);                            // Get time in sec since Epoch
      localtime_r(&timeinsecs,&ltz);                // Convert to UTC time
      strftime(__result, 20, "%F %H:%M:%S", &ltz);  // Formats yyyy-mm-dd hh:mi:ss
    ENDC++;

    RETURN getNow();
  END;
END;
