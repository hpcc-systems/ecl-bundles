/*******************************************************************************
 * SysTime.ecl
 * 
 * Useful time- and date-oriented utilities.
 * 
 * Copyright (C) 2013, Dun & Bradstreet
 ******************************************************************************/

IMPORT Std;

EXPORT  SysTime := MODULE,FORWARD
    
    /***************************************************************************
     * Exported Types and Data Structures
     *
     *  - Time_t                Type representing the number of seconds
     *                          since epoch (UTC).
     *  - TMField (ENUM)        Individual enum values that map to the fields
     *                          used in the system's tm struct.
     *  - TMDict (DICTIONARY)   Collection of TMField enums and their values.
     * 
     * Exported Functions
     *
     *    FUNCTION NAME                     CONVERSION PERFORMED
     *    =============                     ====================
     *  - CurrentUTCTimeInSeconds           ()              -> Time_t
     *  - FormattedTime                     Time_t          -> STRING
     *  - MakeTimeInSecondsFromTimeParts    timeParts       -> Time_t
     *  - MakeTMDictFromTimeInSeconds       Time_t          -> TMDict
     *  - MakeTimeInSecondsFromTMDict       TMDict          -> Time_t
     *  - MakeTMDictFromDate                Std.Date.Date_t -> TMDict
     *  - MakeDateFromTMDict                TMDict          -> Std.Date.Date_t
     *  - DateFromTimeInSeconds             Time_t          -> Std.Date.Date_t
     *  - TimeInSecondsFromDate             Std.Date.Date_t -> Time_t
     *  - CurrentDate                       ()              -> Std.Date.Date_t
     *  - CurrentISODate                    ()              -> String
     *  - TimeZoneOffsetToSeconds           String          -> INTEGER4
     *  - LocalTimeZoneOffset               ()              -> STRING
     *  - LocalTimeZoneOffsetInSeconds      ()              -> INTEGER4
     *  - AdjustTimeInSeconds               Time_t          -> Time_t
     *  - AdjustDate                        Std.Date.Date_t -> Std.Date.Date_t
     *
     * Exported Modules
     *
     *  - TM                    Pass in a TMDict and use exported attributes
     *                          to more easily pick out discrete values
     *      - Year                      Four-digit year
     *      - MonthNum                  1-12
     *      - Day                       1-31
     *      - Hour                      0-23
     *      - Minute                    0-59
     *      - Second                    0-59
     *      - DayOfWeekNum              0-6 (0 = Sunday)
     *      - DayOfYearNum              0-365 (0 = January 1)
     *      - WeekOfYearNum             1-53; Adheres to ISO 8601 (significantly, Monday is the first day of a week)
     *      - IsDaylightSavingsTime     TRUE | FALSE
     *      - IsLeapYear                TRUE | FALSE
     *
     * Testing
     *
     *  - SysTime.__selfTest.testAll;
     **************************************************************************/
    
    /***************************************************************************
     * Bundle declaration
     **************************************************************************/
    EXPORT  Bundle := MODULE(Std.BundleBase)
        EXPORT Name := 'SysTime';
        EXPORT Description := 'Useful time- and date-oriented utilities';
        EXPORT Authors := ['Dan S. Camper (camperd@dnb.com)'];
        EXPORT License := 'http://www.apache.org/licenses/LICENSE-2.0';
        EXPORT Copyright := 'Copyright (C) 2013, Dun & Bradstreet';
        EXPORT DependsOn := [];
        EXPORT Version := '1.0.0';
        EXPORT PlatformVersion := '4.0.0';
    END;
    
    /***************************************************************************
     * Enumeration of fields defined in struct tm.  Please see man page for
     * a time-oriented system call (e.g. localtime()) for more information
     * about the values associated with these fields.
     *
     * @see TMDict
     **************************************************************************/
    EXPORT  TMField := ENUM
        (
            UNSIGNED2,      // VALUES
            tm_sec = 1,     // 0-59 (could be 60 if leap seconds involved)
            tm_min,         // 0-59
            tm_hour,        // 0-23
            tm_mday,        // 1-31
            tm_mon,         // 0-11
            tm_year,        // (Number of years since 1900)
            tm_wday,        // 0-6, 0 = Sunday
            tm_yday,        // 0-365, 0 = Jan. 1
            tm_isdst        // >0 = true, 0 = false, -1 = not available
        );
    
    /***************************************************************************
     * Typedef defining a dictionary containing struct tm values.
     **************************************************************************/
    EXPORT  TMDict := DICTIONARY({TMField f => INTEGER2 v});
    
    /***************************************************************************
     * Module for easier (and more readable) access to TMDict values
     **************************************************************************/
    EXPORT  TM(TMDict tmValues) := MODULE
        EXPORT  Year := tmValues[TMField.tm_year].v + 1900;
        EXPORT  MonthNum := tmValues[TMField.tm_mon].v + 1;
        EXPORT  Day := tmValues[TMField.tm_mday].v;
        EXPORT  Hour := tmValues[TMField.tm_hour].v;
        EXPORT  Minute := tmValues[TMField.tm_min].v;
        EXPORT  Second := tmValues[TMField.tm_sec].v;
        EXPORT  DayOfWeekNum := tmValues[TMField.tm_wday].v;
        EXPORT  DayOfYearNum := tmValues[TMField.tm_yday].v;
        EXPORT  WeekOfYearNum := TRUNCATE((tmValues[TMField.tm_yday].v + 7 - IF(tmValues[TMField.tm_wday].v > 0,(tmValues[TMField.tm_wday].v - 1),6)) / 7) + 1;
        EXPORT  IsDaylightSavingsTime := (tmValues[TMField.tm_isdst].v > 0);
        EXPORT  IsLeapYear := ((Year % 4 = 0) AND (Year % 100 != 0)) OR (Year % 400 = 0);
    END;
    
    /***************************************************************************
     * Typedef representing number of seconds since epoch (UTC)
     **************************************************************************/
    EXPORT  Time_t := UNSIGNED4;
    
    /***************************************************************************
     * Current UTC time in seconds.
     * 
     * @return  The current UTC time in seconds since epoch.
     **************************************************************************/
    EXPORT  Time_t CurrentUTCTimeInSeconds() := BEGINC++
        #option pure
        #option action
        #include <time.h>
        #body
        
        unsigned int    result = time(NULL);
        
        return result;
    ENDC++;
    
    /***************************************************************************
     * Converts a UTC time represented in seconds to a readable string.
     *
     * @param   time_in_seconds Integer representing the number of seconds
     *                          since epoch (UTC).
     * @param   format          The string format to use to create the
     *                          result.  See man page for strftime.  The
     *                          resulting string should not be greater
     *                          than 256 bytes.  Optional; defaults to
     *                          '%FT%T' which is YYYY-MM-DDTHH:MM:SS.
     * @param   as_local_time   If TRUE, time_in_seconds is converted to
     *                          local time during the conversion to a
     *                          readable value.  Optional; defaults to FALSE.
     * 
     * @return                  A string representing the given time converted
     *                          to a readable date/time as per the value of
     *                          the format argument.
     **************************************************************************/
    EXPORT  STRING FormattedTime(Time_t time_in_seconds,
                                 VARSTRING format = '%FT%T',
                                 BOOLEAN as_local_time = FALSE) := BEGINC++
        #option pure
        #include <time.h>
        
        #body
        
        struct tm           timeInfo;
        time_t              theTime = time_in_seconds;
        size_t              kBufferSize = 256;
        char                buffer[kBufferSize];
        int                 numCharsInResult = 0;
        
        memset(buffer,kBufferSize,0);
        
        // Create time parts differently depending on whether you need
        // UTC or local time
        if (as_local_time)
        {
            memcpy(&timeInfo,localtime(&theTime),sizeof(timeInfo));
        }
        else
        {
            memcpy(&timeInfo,gmtime(&theTime),sizeof(timeInfo));
        }
        
        numCharsInResult = strftime(buffer,kBufferSize,format,&timeInfo);
        
        __lenResult = numCharsInResult;
        __result = NULL;
        
        if (__lenResult > 0)
        {
            __result = reinterpret_cast<char*>(rtlMalloc(__lenResult));
            memcpy(__result,buffer,__lenResult);
        }
    ENDC++;
    
    /***************************************************************************
     * Given date and time values, return the equivalent time in seconds
     * since epoch (UTC).
     *
     * @param   year            The four-digit year.
     * @param   month           The number of the month, range 1-12.
     * @param   day             The day number of the month, range 1-31.
     * @param   hours           The hour, range 0-23.  Optional;
     *                          defaults to 0.
     * @param   minutes         The minute, range 0-59.  Optional; defaults
     *                          to 0.
     * @param   seconds         The seconds, range 0-59.  Optional; defaults
     *                          to 0.
     * @param   is_dst          Whether daylight savings time is in effect
     *                          or not.  Valid only if as_local_time is TRUE.
     *                          Use 1=DST in effect, 0=DST not in effect.
     *                          Optional; defaults to 0.
     * @param   as_local_time   If TRUE, the values are interpreted as local
     *                          time rather than UTC time.  Optional;
     *                          defaults to FALSE.
     * 
     * @return                  The time in seconds since epoch (UTC).
     **************************************************************************/
    EXPORT  Time_t MakeTimeInSecondsFromTimeParts(INTEGER2 year,
                                                  INTEGER2 month,
                                                  INTEGER2 day,
                                                  INTEGER2 hours = 0,
                                                  INTEGER2 minutes = 0,
                                                  INTEGER2 seconds = 0,
                                                  INTEGER2 is_dst = 0,
                                                  BOOLEAN as_local_time = FALSE) := BEGINC++
        #option pure
        #include <time.h>
        
        #body
    
        struct tm   timeInfo;
        time_t      the_time;
        
        // Push each time part value into the tm struct
        timeInfo.tm_sec = seconds;
        timeInfo.tm_min = minutes;
        timeInfo.tm_hour = hours;
        timeInfo.tm_mday = day;
        timeInfo.tm_mon = month - 1;
        timeInfo.tm_year = year - 1900;
        timeInfo.tm_wday = 0;
        timeInfo.tm_yday = 0;
        timeInfo.tm_isdst = is_dst;
        
        // Convert time parts to 'time since epoch' differently, depending
        // on whether the time parts were originally local or UTC
        if (as_local_time)
        {
            the_time = mktime(&timeInfo);
        }
        else
        {
            char*               tz = NULL;
            const char*         kTZName = "TZ";
    
            tz = getenv(kTZName);
            setenv(kTZName,"",1);
            tzset();
            
            the_time = mktime(&timeInfo);
            
            if (tz)
            {
                setenv(kTZName,tz,1);
            }
            else
            {
                unsetenv(kTZName);
            }
            tzset();
        }
        
        return the_time;
    ENDC++;
    
    /***************************************************************************
     * Converts a UTC time represented in seconds to a TMDict record, which
     * contains individual time components broken out.
     *
     * @param   time_in_seconds Integer representing the number of seconds
     *                          since epoch (UTC).
     * @param   as_local_time   If TRUE, time_in_seconds is converted to
     *                          local time.  Optional; defaults to FALSE.
     * 
     * @return                  TMDict instance.
     **************************************************************************/
    EXPORT  TMDict MakeTMDictFromTimeInSeconds(Time_t time_in_seconds,
                                               BOOLEAN as_local_time = FALSE) := FUNCTION
        
        TMRec := RECORD
            TMField     f;
            INTEGER2    v;
        END;
        
        // Private C++ function to make the system call
        DATASET(TMRec) _MakeTimeParts(Time_t the_time, BOOLEAN use_local) := BEGINC++
            #option pure
            #include <time.h>
            #body
        
            struct tm   timeInfo;
            time_t      theTime = the_time;
            
            // Create time parts differently depending on whether you need
            // UTC or local time
            if (use_local)
            {
                memcpy(&timeInfo,localtime(&theTime),sizeof(timeInfo));
            }
            else
            {
                memcpy(&timeInfo,gmtime(&theTime),sizeof(timeInfo));
            }
            
            // Set the internal response variables so the caller knows how
            // to read the response
            __lenResult = (sizeof(unsigned short) + sizeof(signed short)) * 9;
            __result = rtlMalloc(__lenResult);
            
            // Actually write the output values, building up the key/value
            // records one at a time
            signed short*   out = reinterpret_cast<signed short*>(__result);
        
            out[0] = 1;                     // TMField.tm_sec
            out[1] = timeInfo.tm_sec;
        
            out[2] = 2;                     // TMField.tm_min
            out[3] = timeInfo.tm_min;
        
            out[4] = 3;                     // TMField.tm_hour
            out[5] = timeInfo.tm_hour;
        
            out[6] = 4;                     // TMField.tm_mday
            out[7] = timeInfo.tm_mday;
        
            out[8] = 5;                     // TMField.tm_mon
            out[9] = timeInfo.tm_mon;
        
            out[10] = 6;                    // TMField.tm_year
            out[11] = timeInfo.tm_year;
        
            out[12] = 7;                    // TMField.tm_wday
            out[13] = timeInfo.tm_wday;
        
            out[14] = 8;                    // TMField.tm_yday
            out[15] = timeInfo.tm_yday;
        
            out[16] = 9;                    // TMField.tm_isdst
            out[17] = timeInfo.tm_isdst;
        ENDC++;
        
        // Call private C++ function to do the heavy lifting
        d := _MakeTimeParts(time_in_seconds,as_local_time);
        
        RETURN DICTIONARY(d,{f => v});
    END;
    
    /***************************************************************************
     * Converts a TMDict record, which contains individual time components,
     * to a UTC time.
     *
     * @param   time_parts      TMDict containing broken-out time components
     *                          (such as the return value of
     *                          MakeTMDictFromTimeInSeconds()).
     *                          since epoch (UTC).
     * @param   as_local_time   If TRUE, time_parts is interpreted as containing
     *                          local time rather than UTC time.  Optional;
     *                          defaults to FALSE.
     * 
     * @return                  The time in seconds since epoch (UTC).
     **************************************************************************/
    EXPORT  Time_t MakeTimeInSecondsFromTMDict(TMDict time_parts,
                                               BOOLEAN as_local_time = FALSE) := FUNCTION
        RETURN MakeTimeInSecondsFromTimeParts
            (
                time_parts[TMField.tm_year].v + 1900,
                time_parts[TMField.tm_mon].v + 1,
                time_parts[TMField.tm_mday].v,
                time_parts[TMField.tm_hour].v,
                time_parts[TMField.tm_min].v,
                time_parts[TMField.tm_sec].v,
                time_parts[TMField.tm_isdst].v,
                as_local_time
            );
    END;
    
    /***************************************************************************
     * Converts a standard date to a TMDict record, which contains individual
     * time components broken out.
     *
     * @param   the_date        A date in Std.Date.Date_t format.
     * 
     * @return                  TMDict instance.
     **************************************************************************/
    EXPORT  TMDict MakeTMDictFromDate(Std.Date.Date_t the_date) := FUNCTION
        seconds := MakeTimeInSecondsFromTimeParts
            (
                Std.Date.Year(the_date),
                Std.Date.Month(the_date),
                Std.Date.Day(the_date)
            );
        
        RETURN MakeTMDictFromTimeInSeconds(seconds);
    END;
    
    /***************************************************************************
     * Converts a TMDict record, which contains individual time components,
     * to a standard date.
     *
     * @param   time_parts      TMDict containing broken-out time components
     *                          (such as the return value of
     *                          MakeTMDictFromTimeInSeconds()).
     *                          since epoch (UTC).
     * 
     * @return                  The date in Std.Date.Date_t format.
     **************************************************************************/
    EXPORT  Std.Date.Date_t MakeDateFromTMDict(TMDict time_parts) := FUNCTION
        year := time_parts[TMField.tm_year].v + 1900;
        month := time_parts[TMField.tm_mon].v + 1;
        day := time_parts[TMField.tm_mday].v;
        
        RETURN (year * 10000) + (month * 100) + day;
    END;
    
    /***************************************************************************
     * Converts time in seconds into a date.
     *
     * @param   time_in_seconds Integer representing the number of seconds
     *                          since epoch (UTC).
     * @param   as_local_time   If TRUE, time_in_seconds is converted to
     *                          local time.  Optional; defaults to FALSE.
     * 
     * @return  The date in Std.Date.Date_t format.
     **************************************************************************/
    EXPORT  Std.Date.Date_t DateFromTimeInSeconds(Time_t time_in_seconds,
                                                  BOOLEAN as_local_time = FALSE) := BEGINC++
        
        #option pure
        #include <time.h>
        #body
    
        struct tm       timeInfo;
        time_t          theTime = time_in_seconds;
        unsigned int    theDate = 0;
        
        // Create time parts differently depending on whether you need
        // UTC or local time
        if (as_local_time)
        {
            memcpy(&timeInfo,localtime(&theTime),sizeof(timeInfo));
        }
        else
        {
            memcpy(&timeInfo,gmtime(&theTime),sizeof(timeInfo));
        }
        
        theDate = (timeInfo.tm_year + 1900) * 10000;
        theDate += (timeInfo.tm_mon + 1) * 100;
        theDate += timeInfo.tm_mday;
        
        return theDate;
    ENDC++;
    
    /***************************************************************************
     * Converts a standard date into time in seconds.
     *
     * @param   the_date        A date in Std.Date.Date_t format.
     * @param   as_local_time   If TRUE, the_date is interpreted as local time.
     *                          Optional; defaults to FALSE.
     * 
     * @return  The time in seconds since epoch (UTC).
     **************************************************************************/
    EXPORT  Time_t TimeInSecondsFromDate(Std.Date.Date_t the_date,
                                         BOOLEAN as_local_time = FALSE) := FUNCTION
        RETURN MakeTimeInSecondsFromTimeParts
            (
                Std.Date.Year(the_date),
                Std.Date.Month(the_date),
                Std.Date.Day(the_date),
                as_local_time := as_local_time
            );
    END;
    
    /***************************************************************************
     * Returns the current date in standard library format.
     *
     * @param   as_local_time   If TRUE, the local time zone is used to
     *                          determine the current date.  Optional;
     *                          defaults to FALSE.
     * 
     * @return  The current date in Std.Date.Date_t format.
     **************************************************************************/
    EXPORT  Std.Date.Date_t CurrentDate(BOOLEAN as_local_time = FALSE) := FUNCTION
        RETURN DateFromTimeInSeconds(CurrentUTCTimeInSeconds(),as_local_time);
    END;
    
    /***************************************************************************
     * Returns the current date in ISO format.
     *
     * @param   as_local_time   If TRUE, the local time zone is used to
     *                          determine the current date.  Optional;
     *                          defaults to FALSE.
     * 
     * @return  The current date as a string in ISO format (YYYY-MM-DD).
     **************************************************************************/
    EXPORT  STRING CurrentISODate(BOOLEAN as_local_time = FALSE) := FUNCTION
        RETURN FormattedTime(CurrentUTCTimeInSeconds(),'%F',as_local_time);
    END;
    
    /***************************************************************************
     * Convert between the string representation of a timezone offset (as if
     * returned from LocalTimeZoneOffset()) and a number of seconds.
     *
     * @param   timeZoneOffset  String representing a time zone offset (example:
     *                          Central Daylight Time = "-0500").
     * 
     * @return                  The number of seconds the offset represents.
     *                          This can be applied to a timestamp value to
     *                          convert between UTC and another time zone.
     **************************************************************************/
    EXPORT  INTEGER4 TimeZoneOffsetToSeconds(STRING timeZoneOffset) := FUNCTION
        offsetLength := LENGTH(timeZoneOffset);
        minutes := (INTEGER2)timeZoneOffset[offsetLength-1..] * 60;
        hours := (INTEGER2)timeZoneOffset[..offsetLength-2] * 60 * 60;
        offsetSeconds := hours + IF(hours > 0,minutes,(-1*minutes));
        
        RETURN IF(offsetLength = 4 OR offsetLength = 5,offsetSeconds,0);
    END;
    
    /***************************************************************************
     * Returns the local timezone offset as a string.
     * 
     * @return  Returns a string representing the local time zone offset from
     *          UTC.  Example:  Central Daylight Time = "-0500".  The first
     *          two digits represent hours, the last two represent minutes.
     **************************************************************************/
    EXPORT  STRING LocalTimeZoneOffset() := FUNCTION
        RETURN FormattedTime(CurrentUTCTimeInSeconds(),'%z',TRUE);
    END;
    
    /***************************************************************************
     * Returns the local timezone offset as a number of seconds.
     * 
     * @return  Returns an integer representing the local time zone offset, in
     *          seconds, from UTC.
     **************************************************************************/
    EXPORT  INTEGER2 LocalTimeZoneOffsetInSeconds() := FUNCTION
        offsetString := FormattedTime(CurrentUTCTimeInSeconds(),'%z',TRUE);
        
        RETURN TimeZoneOffsetToSeconds(offsetString);
    END;
    
    /***************************************************************************
     * Adjust a time in seconds value.
     *
     * @param   time_in_seconds Integer representing the number of seconds
     *                          since epoch.
     * @param   delta_years     The number of years to apply.  A positive
     *                          number indicates a future time.
     * @param   delta_months    The number of months to apply.  A positive
     *                          number indicates a future time.
     * @param   delta_days      The number of days to apply.  A positive
     *                          number indicates a future time.
     * @param   delta_hours     The number of hours to apply.  A positive
     *                          number indicates a future time.
     * @param   delta_minutes   The number of minutes to apply.  A positive
     *                          number indicates a future time.
     * @param   delta_seconds   The number of seconds to apply.  A positive
     *                          number indicates a future time.
     * 
     * @return  Returns an integer representing the local time zone offset, in
     *          seconds, from UTC.
     **************************************************************************/
    EXPORT  Time_t AdjustTimeInSeconds(Time_t time_in_seconds,
                                       INTEGER2 delta_years = 0,
                                       INTEGER2 delta_months = 0,
                                       INTEGER2 delta_days = 0,
                                       INTEGER2 delta_hours = 0,
                                       INTEGER2 delta_minutes = 0,
                                       INTEGER2 delta_seconds = 0) := BEGINC++
        #option pure
        #include <time.h>
        #body
    
        struct tm       timeInfo;
        time_t          theTime = time_in_seconds;
    
        memcpy(&timeInfo,localtime(&theTime),sizeof(timeInfo));
        
        timeInfo.tm_year += delta_years;
        timeInfo.tm_mon += delta_months;
        timeInfo.tm_mday += delta_days;
        timeInfo.tm_hour += delta_hours;
        timeInfo.tm_min += delta_minutes;
        timeInfo.tm_sec += delta_seconds;
        
        return mktime(&timeInfo);
    ENDC++;
    
    /***************************************************************************
     * Adjust a standard date value.
     *
     * @param   the_date        A date in Std.Date.Date_t format.
     * @param   delta_years     The number of years to apply.  A positive
     *                          number indicates a future time.
     * @param   delta_months    The number of months to apply.  A positive
     *                          number indicates a future time.
     * @param   delta_days      The number of days to apply.  A positive
     *                          number indicates a future time.
     * 
     * @return  A date in Std.Date.Date_t format.
     **************************************************************************/
    EXPORT  Std.Date.Date_t AdjustDate(Std.Date.Date_t the_date,
                                       INTEGER2 delta_years = 0,
                                       INTEGER2 delta_months = 0,
                                       INTEGER2 delta_days = 0) := BEGINC++
        #option pure
        #include <time.h>
        #body
    
        struct tm       timeInfo;
        unsigned int    year = the_date / 10000;
        unsigned int    month = (the_date - (year * 10000)) / 100;
        unsigned int    day = the_date - (year * 10000) - (month * 100);
        unsigned int    result = 0;
        
        memset(&timeInfo,0,sizeof(timeInfo));
        
        timeInfo.tm_year = year - 1900;
        timeInfo.tm_mon = month - 1;
        timeInfo.tm_mday = day;
        timeInfo.tm_hour = 0;
        timeInfo.tm_min = 0;
        timeInfo.tm_sec = 0;
        
        timeInfo.tm_year += delta_years;
        timeInfo.tm_mon += delta_months;
        timeInfo.tm_mday += delta_days;
        
        mktime(&timeInfo);
        
        result = (timeInfo.tm_year + 1900) * 10000;
        result += (timeInfo.tm_mon + 1) * 100;
        result += timeInfo.tm_mday;
        
        return result;
    ENDC++;
    
    /***************************************************************************
     * Self test
     **************************************************************************/
    EXPORT  __selfTest := MODULE
        
        SHARED  Time_t          testTime := 1356998400;         // UTC Time since epoch for midnight Jan. 1, 2013
        SHARED  Std.Date.Date_t testDate := 20130101;           // Date for Jan. 1, 2013
        SHARED  Time_t          adjustedTestTime := 1356994800; // UTC time since epoch for Dec. 31, 2012 @ 11pm
        SHARED  Std.Date.Date_t adjustedTestDate := 20121231;   // Date for Dec. 31, 2012
        SHARED  STRING          fullyFormattedTestTime := '2013-01-01T00:00:00';
        SHARED  STRING          isoFormattedTestTime := '2013-01-01';
        SHARED  STRING          testTimeZone := '-0500';
        SHARED  INTEGER2        testTimeZoneSeconds := -18000;
        
        SHARED  timeNow := CurrentUTCTimeInSeconds();
        SHARED  dateNow := CurrentDate();
        SHARED  constructedTestTime := MakeTimeInSecondsFromTimeParts(2013,1,1);
        SHARED  testTimeDict := MakeTMDictFromTimeInSeconds(testTime);
        SHARED  testDateDict := MakeTMDictFromDate(testDate);
        SHARED  timeFromTimeDict := MakeTimeInSecondsFromTMDict(testTimeDict);
        SHARED  timeFromDateDict := MakeTimeInSecondsFromTMDict(testDateDict);
        SHARED  dateFromTimeDict := MakeDateFromTMDict(testTimeDict);
        SHARED  dateFromDateDict := MakeDateFromTMDict(testDateDict);
        SHARED  formattedTestTime := FormattedTime(testTime);
        SHARED  dateFromTestTime := DateFromTimeInSeconds(testTime);
        SHARED  timeFromTestDate := TimeInSecondsFromDate(testDate);
        SHARED  isoDateNow := CurrentISODate();
        SHARED  localTimeZoneOffsetStr := LocalTimeZoneOffset();
        SHARED  oneTimeZoneOffsetNum := TimeZoneOffsetToSeconds(testTimeZone);
        SHARED  testTimeMinusOneHour := AdjustTimeInSeconds(testTime,delta_hours:=-1);
        SHARED  testDateMinusOneDay := AdjustDate(testDate,delta_days:=-1);
        
        EXPORT  testAll :=
            [
                ASSERT(timeNow > testTime, 'Time now not greater than test time: (' + timeNow + '>' + testTime + ')'),
                ASSERT(dateNow > testDate, 'Date now not greater than test date: (' + dateNow + '>' + testDate + ')'),
                ASSERT(constructedTestTime = testTime, 'Constructed test time not equal to test time: (' + constructedTestTime + '=' + testTime + ')'),
                ASSERT(TM(testTimeDict).Year = 2013, 'Test time dictionary year incorrect: (' + TM(testTimeDict).Year + '=2013)'),
                ASSERT(TM(testTimeDict).MonthNum = 1, 'Test time dictionary month incorrect: (' + TM(testTimeDict).MonthNum + '=1)'),
                ASSERT(TM(testTimeDict).Day = 1, 'Test time dictionary day incorrect: (' + TM(testTimeDict).Day + '=1)'),
                ASSERT(TM(testTimeDict).Hour = 0, 'Test time dictionary hour incorrect: (' + TM(testTimeDict).Hour + '=0)'),
                ASSERT(TM(testTimeDict).Minute = 0, 'Test time dictionary minute incorrect: (' + TM(testTimeDict).Minute + '=0)'),
                ASSERT(TM(testTimeDict).Second = 0, 'Test time dictionary second incorrect: (' + TM(testTimeDict).Second + '=0)'),
                ASSERT(TM(testTimeDict).DayOfWeekNum = 2, 'Test time dictionary day of week number incorrect: (' + TM(testTimeDict).DayOfWeekNum + '=2)'),
                ASSERT(TM(testTimeDict).DayOfYearNum = 0, 'Test time dictionary day of year number incorrect: (' + TM(testTimeDict).DayOfYearNum + '=0)'),
                ASSERT(TM(testTimeDict).WeekOfYearNum = 1, 'Test time dictionary week number of year number incorrect: (' + TM(testTimeDict).WeekOfYearNum + '=1)'),
                ASSERT(TM(testDateDict).Year = 2013, 'Test date dictionary year incorrect: (' + TM(testDateDict).Year + '=2013)'),
                ASSERT(TM(testDateDict).MonthNum = 1, 'Test date dictionary month incorrect: (' + TM(testDateDict).MonthNum + '=1)'),
                ASSERT(TM(testDateDict).Day = 1, 'Test date dictionary day incorrect: (' + TM(testDateDict).Day + '=1)'),
                ASSERT(TM(testDateDict).Hour = 0, 'Test date dictionary hour incorrect: (' + TM(testDateDict).Hour + '=0)'),
                ASSERT(TM(testDateDict).Minute = 0, 'Test date dictionary minute incorrect: ( ' + TM(testDateDict).Minute + '=0)'),
                ASSERT(TM(testDateDict).Second = 0, 'Test date dictionary second incorrect: (' + TM(testDateDict).Second + '=0)'),
                ASSERT(TM(testDateDict).DayOfWeekNum = 2, 'Test date dictionary day of week number incorrect: (' + TM(testDateDict).DayOfWeekNum + '=2)'),
                ASSERT(TM(testDateDict).DayOfYearNum = 0, 'Test date dictionary day of year number incorrect: (' + TM(testDateDict).DayOfYearNum + '=0)'),
                ASSERT(TM(testDateDict).WeekOfYearNum = 1, 'Test date dictionary week number of year number incorrect: (' + TM(testDateDict).WeekOfYearNum + '=1)'),
                ASSERT(timeFromTimeDict = timeFromDateDict, 'Times from test time and test date dictionaries not equal: (' + timeFromTimeDict + '=' + timeFromDateDict + ')'),
                ASSERT(dateFromTimeDict = dateFromDateDict, 'Dates from test time and test date dictionaries not equal: (' + dateFromTimeDict + '=' + dateFromDateDict + ')'),
                ASSERT(formattedTestTime = fullyFormattedTestTime, 'Fully formatted test time incorrect: (' + formattedTestTime + '=' + fullyFormattedTestTime + ')'),
                ASSERT(dateFromTestTime = testDate, 'Date from test time not equal to test date: (' + dateFromTestTime + '=' + testDate + ')'),
                ASSERT(timeFromTestDate = testTime, 'Time from test date not equal to test time: (' + timeFromTestDate + '=' + testTime + ')'),
                ASSERT(isoDateNow > isoFormattedTestTime, 'Current ISO Date not greater than test ISO date: (' + isoDateNow + '>' + isoFormattedTestTime + ')'),
                ASSERT(localTimeZoneOffsetStr != '', 'Local time zone offset string is empty: (' + localTimeZoneOffsetStr + '!=' + '\'\''),
                ASSERT(oneTimeZoneOffsetNum = testTimeZoneSeconds, 'Time zone ' + testTimeZone + ' string not correctly translated to seconds: (' + oneTimeZoneOffsetNum + '=' + testTimeZoneSeconds + ')'),
                ASSERT(testTimeMinusOneHour = adjustedTestTime, 'Adjusted test time incorrect: (' + testTimeMinusOneHour + '=' + adjustedTestTime + ')'),
                ASSERT(testDateMinusOneDay = adjustedTestDate, 'Adjusted test date incorrect: (' + testDateMinusOneDay + '=' + adjustedTestDate + ')')
            ];
        
    END;    // __selfTest Module

END;    // SysTime Module
