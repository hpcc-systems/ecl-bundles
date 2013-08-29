IMPORT Std;

EXPORT	SysTime := MODULE,FORWARD
	
	/***************************************************************************
	 * Export Types and Data Structures
	 *
	 *	- TMField (ENUM)		Individual enum values that map to the fields
	 *							used in the system's tm struct.
	 *	- TMDict (DICTIONARY)	Collection of TMField enums and their values.
	 * 
	 * Exported functions
	 *
	 * 	- CurrentUTCTimeInSeconds
	 *	- MakeTMDictFromTimeInSeconds
	 *	- MakeTimeInSecondsFromTMDict
	 *	- FormattedTime
	 *	- DateFromTimeInSeconds
	 *	- CurrentDate
	 *	- CurrentISODate
	 *	- TimeZoneOffsetToSeconds
	 *	- LocalTimeZoneOffset
	 *	- LocalTimeZoneOffsetInSeconds
	 *	- AdjustTimeInSeconds
	 *	- AdjustDate
	 *
	 * @see	TMDict
	 **************************************************************************/
	
	/***************************************************************************
	 * Bundle declaration
	 **************************************************************************/
	EXPORT	Bundle := MODULE(Std.BundleBase)
		EXPORT Name := 'SysTime';
		EXPORT Description := 'Useful time- and date-oriented utilities';
		EXPORT Authors := ['Dan S. Camper (camperd@dnb.com)'];
		EXPORT License := 'http://www.apache.org/licenses/LICENSE-2.0';
		EXPORT Copyright := 'Copyright (C) 2013, Dun & Bradstreet';
		EXPORT DependsOn := [];
		EXPORT Version := '1.0.0';
	END;
	
	/***************************************************************************
	 * Enumeration of fields defined in struct tm.  Please see man page for
	 * a time-oriented system call (e.g. localtime()) for more information
	 * about the values associated with these fields.
	 *
	 * @see	TMDict
	 **************************************************************************/
	EXPORT	TMField := ENUM
		(
			UNSIGNED2,
			tm_sec = 1,
			tm_min,
			tm_hour,
			tm_mday,
			tm_mon,
			tm_year,
			tm_wday,
			tm_yday,
			tm_isdst
		);
	
	/***************************************************************************
	 * Typedef defining a dictionary containing struct tm values.
	 **************************************************************************/
	EXPORT	TMDict := DICTIONARY({TMField f => INTEGER2 v});
	
	/***************************************************************************
	 * Current UTC time in seconds.
	 * 
	 * @return	The current UTC time in seconds since epoch.
	 **************************************************************************/
	EXPORT	UNSIGNED4 CurrentUTCTimeInSeconds() := BEGINC++
		#option pure
		#option action
		#include <time.h>
		#body
		
		struct timeval	tv;
		unsigned int	result = 0;
		
		if (gettimeofday(&tv,NULL) == 0)
		{
			result = tv.tv_sec;
		}
		
		return result;
	ENDC++;
	
	/***************************************************************************
	 * Current UTC time in seconds and microseconds.
	 * 
	 * @return	The current UTC time in seconds since epoch, including
	 *			microsecond precision.
	 **************************************************************************/
	EXPORT	REAL8 CurrentUTCTimeInSecondsWithPrecision() := BEGINC++
		#option pure
		#option action
		#include <time.h>
		#body
		
		struct timeval	tv;
		double			result = 0.0;
		
		if (gettimeofday(&tv,NULL) == 0)
		{
			result = tv.tv_sec + (tv.tv_usec / 1000000.0); 
		}
		
		return result;
	ENDC++;
	
	/***************************************************************************
	 * Converts a UTC time represented in seconds to a TMDict record, which
	 * contains individual time components broken out.
	 *
	 * @param	time_in_seconds	Integer representing the number of seconds
	 *							since epoch (UTC).
	 * @param	as_local_time	If TRUE, time_in_seconds is converted to
	 *							local time.  Optional; defaults to FALSE.
	 * 
	 * @return					DATASET(TMDict) containing only one record.
	 **************************************************************************/
	EXPORT	TMDict MakeTMDictFromTimeInSeconds(UNSIGNED4 time_in_seconds,
											   BOOLEAN as_local_time = FALSE) := FUNCTION
		
		TMRec := RECORD
			TMField		f;
			INTEGER2	v;
		END;
		
		// Private C++ function to make the system call
		DATASET(TMRec) _MakeTimeParts(UNSIGNED4 the_time, BOOLEAN use_local) := BEGINC++
			#option pure
			#include <time.h>
			#body
		
			struct tm	timeInfo;
			time_t		theTime = the_time;
			
			// Create time parts differently depending on whether you need
			// UTC or local time
			if (use_local)
			{
				localtime_r(&theTime,&timeInfo);
			}
			else
			{
				gmtime_r(&theTime,&timeInfo);
			}
			
			// Set the internal response variables so the caller knows how
			// to read the response
			__lenResult = (sizeof(unsigned short) + sizeof(signed short)) * 9;
			__result = rtlMalloc(__lenResult);
			
			// Actually write the output values, building up the key/value
			// records one at a time
			signed short*	out = reinterpret_cast<signed short*>(__result);
		
			out[0] = 1;						// TMField.tm_sec
			out[1] = timeInfo.tm_sec;
		
			out[2] = 2;						// TMField.tm_min
			out[3] = timeInfo.tm_min;
		
			out[4] = 3;						// TMField.tm_hour
			out[5] = timeInfo.tm_hour;
		
			out[6] = 4;						// TMField.tm_mday
			out[7] = timeInfo.tm_mday;
		
			out[8] = 5;						// TMField.tm_mon
			out[9] = timeInfo.tm_mon;
		
			out[10] = 6;					// TMField.tm_year
			out[11] = timeInfo.tm_year;
		
			out[12] = 7;					// TMField.tm_wday
			out[13] = timeInfo.tm_wday;
		
			out[14] = 8;					// TMField.tm_yday
			out[15] = timeInfo.tm_yday;
		
			out[16] = 9;					// TMField.tm_isdst
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
	 * @param	time_parts		TMDict containing broken-out time components
	 *							(such as the return value of
	 *							MakeTMDictFromTimeInSeconds()).
	 *							since epoch (UTC).
	 * @param	as_local_time	If TRUE, time_parts is interpreted as containing
	 *							local time rather than UTC time.  Optional;
	 *							defaults to FALSE.
	 * 
	 * @return					The time in seconds since epoch (UTC).
	 **************************************************************************/
	EXPORT	UNSIGNED4 MakeTimeInSecondsFromTMDict(TMDict time_parts,
												  BOOLEAN as_local_time = FALSE) := FUNCTION
		
		// Private C++ function to make the system call
		UNSIGNED4 _ConvertTime(INTEGER2 seconds,
							   INTEGER2 minutes,
							   INTEGER2 hours,
							   INTEGER2 mday,
							   INTEGER2 month,
							   INTEGER2 year,
							   INTEGER2 weekday,
							   INTEGER2 dayofyear,
							   INTEGER2 isdst,
							   BOOLEAN use_local) := BEGINC++
			#option pure
			#include <time.h>
			#body
		
			struct tm	timeInfo;
			time_t		the_time;
			
			// Push each time part value into the tm struct
			timeInfo.tm_sec = seconds;
			timeInfo.tm_min = minutes;
			timeInfo.tm_hour = hours;
			timeInfo.tm_mday = mday;
			timeInfo.tm_mon = month;
			timeInfo.tm_year = year;
			timeInfo.tm_wday = weekday;
			timeInfo.tm_yday = dayofyear;
			timeInfo.tm_isdst = isdst;
			
			// Convert time parts to 'time since epoch' differently, depending
			// on whether the time parts were originally local or UTC
			if (use_local)
			{
				the_time = mktime(&timeInfo);
			}
			else
			{
				char*				tz = NULL;
				const char*			tzName = "TZ";
				pthread_mutex_t		getEnvMutex = PTHREAD_MUTEX_INITIALIZER;
				
				// Mutex stuff required because env manipulation is not
				// thread safe
				
				pthread_mutex_lock(&getEnvMutex);
		
				tz = getenv(tzName);
				setenv(tzName,"",1);
				tzset();
				
				the_time = mktime(&timeInfo);
				
				if (tz)
				{
					setenv(tzName,tz,1);
				}
				else
				{
					unsetenv(tzName);
				}
				tzset();
		
				pthread_mutex_unlock(&getEnvMutex);
			}
			
			return the_time;
		ENDC++;
		
		
		// Call private C++ function to do the heavy lifting
		RETURN _ConvertTime
			(
				time_parts[TMField.tm_sec].v,
				time_parts[TMField.tm_min].v,
				time_parts[TMField.tm_hour].v,
				time_parts[TMField.tm_mday].v,
				time_parts[TMField.tm_mon].v,
				time_parts[TMField.tm_year].v,
				time_parts[TMField.tm_wday].v,
				time_parts[TMField.tm_yday].v,
				time_parts[TMField.tm_isdst].v,
				as_local_time
			);
	END;
	
	/***************************************************************************
	 * Converts a UTC time represented in seconds to a readable string.
	 *
	 * @param	time_in_seconds	Integer representing the number of seconds
	 *							since epoch (UTC).
	 * @param	format			The string format to use to create the
	 *							result.  See man page for strftime.  The
	 *							resulting string should not be greater
	 *							than 256 bytes.  Optional; defaults to
	 *							'%FT%T' which is YYYY-MM-DDTHH:MM:SS.
	 * @param	as_local_time	If TRUE, time_in_seconds is converted to
	 *							local time during the conversion to a
	 *							readable value.  Optional; defaults to FALSE.
	 * 
	 * @return					A string representing the given time converted
	 *							to a readable date/time as per the value of
	 *							the format argument.
	 **************************************************************************/
	EXPORT	STRING FormattedTime(UNSIGNED4 time_in_seconds,
								 VARSTRING format = '%FT%T',
								 BOOLEAN as_local_time = FALSE) := BEGINC++
		#option pure
		#include <time.h>
		#include <pthread.h>
		#body
		
		struct tm			timeInfo;
		time_t				theTime = time_in_seconds;
		size_t				kBufferSize = 256;
		char				buffer[kBufferSize];
		pthread_mutex_t		strftimeMutex = PTHREAD_MUTEX_INITIALIZER;
		int					numCharsInResult = 0;
		
		memset(buffer,kBufferSize,0);
		
		// Create time parts differently depending on whether you need
		// UTC or local time
		if (as_local_time)
		{
			localtime_r(&theTime,&timeInfo);
		}
		else
		{
			gmtime_r(&theTime,&timeInfo);
		}
		
		// Mutexes required because strftime() is not thread safe
		pthread_mutex_lock(&strftimeMutex);
		numCharsInResult = strftime(buffer,kBufferSize,format,&timeInfo);
		pthread_mutex_unlock(&strftimeMutex);
		
		__lenResult = numCharsInResult;
		__result = NULL;
		
		if (__lenResult > 0)
		{
			__result = reinterpret_cast<char*>(rtlMalloc(__lenResult));
			memcpy(__result,buffer,__lenResult);
		}
	ENDC++;
	
	/***************************************************************************
	 * Converts time in seconds into a date.
	 *
	 * @param	time_in_seconds	Integer representing the number of seconds
	 *							since epoch (UTC).
	 * @param	as_local_time	If TRUE, time_in_seconds is converted to
	 *							local time.  Optional; defaults to FALSE.
	 * 
	 * @return	The date in Std.Date.Date_t format.
	 **************************************************************************/
	EXPORT	Std.Date.Date_t DateFromTimeInSeconds(UNSIGNED4 time_in_seconds,
												  BOOLEAN as_local_time = FALSE) := FUNCTION
		
		// Private C++ function to make the system call
		UNSIGNED4 _MakeDate(UNSIGNED4 the_time, BOOLEAN use_local) := BEGINC++
			#option pure
			#include <time.h>
			#body
		
			struct tm		timeInfo;
			time_t			theTime = the_time;
			unsigned int	result = 0;
			
			// Create time parts differently depending on whether you need
			// UTC or local time
			if (use_local)
			{
				localtime_r(&theTime,&timeInfo);
			}
			else
			{
				gmtime_r(&theTime,&timeInfo);
			}
			
			result = (timeInfo.tm_year + 1900) * 10000;
			result += (timeInfo.tm_mon + 1) * 100;
			result += timeInfo.tm_mday;
			
			return result;
		ENDC++;
		
		RETURN (Std.Date.Date_t)_MakeDate(time_in_seconds,as_local_time);
	END;
	
	/***************************************************************************
	 * Returns the current date in standard library format.
	 *
	 * @param	as_local_time	If TRUE, the local time zone is used to
	 *							determine the current date.  Optional;
	 *							defaults to FALSE.
	 * 
	 * @return	The current date in Std.Date.Date_t format.
	 **************************************************************************/
	EXPORT	Std.Date.Date_t CurrentDate(BOOLEAN as_local_time = FALSE) := FUNCTION
		RETURN DateFromTimeInSeconds(CurrentUTCTimeInSeconds(),as_local_time);
	END;
	
	/***************************************************************************
	 * Returns the current date in ISO format.
	 *
	 * @param	as_local_time	If TRUE, the local time zone is used to
	 *							determine the current date.  Optional;
	 *							defaults to FALSE.
	 * 
	 * @return	The current date as a string in ISO format (YYYY-MM-DD).
	 **************************************************************************/
	EXPORT	STRING CurrentISODate(BOOLEAN as_local_time = FALSE) := FUNCTION
		RETURN FormattedTime(CurrentUTCTimeInSeconds(),'%F',as_local_time);
	END;
	
	/***************************************************************************
	 * Convert between the string representation of a timezone offset (as if
	 * returned from LocalTimeZoneOffset()) and a number of seconds.
	 *
	 * @param	timeZoneOffset	String representing a time zone offset (example:
	 *							Central Daylight Time = "-0500").
	 * 
	 * @return					The number of seconds the offset represents.
	 *							This can be applied to a timestamp value to
	 *							convert between UTC and another time zone.
	 **************************************************************************/
	EXPORT	INTEGER4 TimeZoneOffsetToSeconds(STRING timeZoneOffset) := FUNCTION
		offsetLength := LENGTH(timeZoneOffset);
		minutes := (INTEGER2)timeZoneOffset[offsetLength-1..] * 60;
		hours := (INTEGER2)timeZoneOffset[..offsetLength-2] * 60 * 60;
		offsetSeconds := hours + IF(hours > 0,minutes,(-1*minutes));
		
		RETURN IF(offsetLength = 4 OR offsetLength = 5,offsetSeconds,0);
	END;
	
	/***************************************************************************
	 * Returns the local timezone offset as a string.
	 * 
	 * @return	Returns a string representing the local time zone offset from
	 *			UTC.  Example:  Central Daylight Time = "-0500".  The first
	 *			two digits represent hours, the last two represent minutes.
	 **************************************************************************/
	EXPORT	STRING LocalTimeZoneOffset() := FUNCTION
		RETURN FormattedTime(CurrentUTCTimeInSeconds(),'%z',TRUE);
	END;
	
	/***************************************************************************
	 * Returns the local timezone offset as a number of seconds.
	 * 
	 * @return	Returns an integer representing the local time zone offset, in
	 *			seconds, from UTC.
	 **************************************************************************/
	EXPORT	INTEGER2 LocalTimeZoneOffsetInSeconds() := FUNCTION
		offsetString := FormattedTime(CurrentUTCTimeInSeconds(),'%z',TRUE);
		
		RETURN TimeZoneOffsetToSeconds(offsetString);
	END;
	
	/***************************************************************************
	 * Adjust a time in seconds value.
	 *
	 * @param	time_in_seconds	Integer representing the number of seconds
	 *							since epoch.
	 * @param	delta_years		The number of years to apply.  A positive
	 *							number indicates a future time.
	 * @param	delta_months	The number of months to apply.  A positive
	 *							number indicates a future time.
	 * @param	delta_days		The number of days to apply.  A positive
	 *							number indicates a future time.
	 * @param	delta_hours		The number of hours to apply.  A positive
	 *							number indicates a future time.
	 * @param	delta_minutes	The number of minutes to apply.  A positive
	 *							number indicates a future time.
	 * @param	delta_seconds	The number of seconds to apply.  A positive
	 *							number indicates a future time.
	 * 
	 * @return	Returns an integer representing the local time zone offset, in
	 *			seconds, from UTC.
	 **************************************************************************/
	EXPORT	UNSIGNED4 AdjustTimeInSeconds(UNSIGNED4 time_in_seconds,
										  INTEGER2 delta_years = 0,
										  INTEGER2 delta_months = 0,
										  INTEGER2 delta_days = 0,
										  INTEGER2 delta_hours = 0,
										  INTEGER2 delta_minutes = 0,
										  INTEGER2 delta_seconds = 0) := BEGINC++
		#option pure
		#include <time.h>
		#body
	
		struct tm		timeInfo;
		time_t			theTime = time_in_seconds;
	
		localtime_r(&theTime,&timeInfo);
		
		timeInfo.tm_year += delta_years;
		timeInfo.tm_mon += delta_months;
		timeInfo.tm_mday += delta_days;
		timeInfo.tm_hour += delta_hours;
		timeInfo.tm_min += delta_minutes;
		timeInfo.tm_sec += delta_seconds;
		
		return mktime(&timeInfo);
	ENDC++;
	
	/***************************************************************************
	 * Adjust a time in seconds value.
	 *
	 * @param	time_in_seconds	Integer representing the number of seconds
	 *							since epoch.
	 * @param	delta_years		The number of years to apply.  A positive
	 *							number indicates a future time.
	 * @param	delta_months	The number of months to apply.  A positive
	 *							number indicates a future time.
	 * @param	delta_days		The number of days to apply.  A positive
	 *							number indicates a future time.
	 * @param	delta_hours		The number of hours to apply.  A positive
	 *							number indicates a future time.
	 * @param	delta_minutes	The number of minutes to apply.  A positive
	 *							number indicates a future time.
	 * @param	delta_seconds	The number of seconds to apply.  A positive
	 *							number indicates a future time.
	 * 
	 * @return	Returns an integer representing the local time zone offset, in
	 *			seconds, from UTC.
	 **************************************************************************/
	EXPORT	UNSIGNED4 AdjustDate(Std.Date.Date_t the_date,
								 INTEGER2 delta_years = 0,
								 INTEGER2 delta_months = 0,
								 INTEGER2 delta_days = 0) := BEGINC++
		#option pure
		#include <time.h>
		#body
	
		struct tm		timeInfo;
		unsigned int	year = the_date / 10000;
		unsigned int	month = (the_date - (year * 10000)) / 100;
		unsigned int	day = the_date - (year * 10000) - (month * 100);
		unsigned int	result = 0;
		
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

END;	// SysTime Module

/*******************************************************************************
// Example ECL

IMPORT SysTime;

timeNow := SysTime.CurrentUTCTimeInSeconds();

OUTPUT(timeNow,NAMED('CurrentUTCTimeInSeconds'));

OUTPUT(SysTime.CurrentUTCTimeInSecondsWithPrecision(),NAMED('CurrentUTCTimeInSecondsWithPrecision'));

OUTPUT(SysTime.FormattedTime(timeNow,as_local_time:=FALSE),NAMED('FormattedTimeUTC'));

OUTPUT(SysTime.FormattedTime(timeNow,as_local_time:=TRUE),NAMED('FormattedTimeLocal'));

struct1 := SysTime.MakeTMDictFromTimeInSeconds(timeNow,as_local_time:=FALSE);
OUTPUT(struct1,NAMED('MakeTMStructFromTimeInSecondsUTC'));

time1 := SysTime.MakeTimeInSecondsFromTMDict(struct1);
OUTPUT(time1,NAMED('MakeTimeInSecondsFromTMStruct1'));

struct2 := SysTime.MakeTMDictFromTimeInSeconds(timeNow,as_local_time:=TRUE);
OUTPUT(struct2,NAMED('MakeTMStructFromTimeInSecondsLocal'));

time2 := SysTime.MakeTimeInSecondsFromTMDict(struct2);
OUTPUT(time2,NAMED('MakeTimeInSecondsFromTMStruct2'));

OUTPUT(SysTime.DateFromTimeInSeconds(timeNow),NAMED('DateFromTimeInSeconds'));

theDate := SysTime.CurrentDate();
OUTPUT(theDate,NAMED('CurrentDate'));

OUTPUT(SysTime.CurrentISODate(),NAMED('CurrentISODate'));

OUTPUT(SysTime.LocalTimeZoneOffset(),NAMED('LocalTimeZoneOffset'));

OUTPUT(SysTime.LocalTimeZoneOffsetInSeconds(),NAMED('LocalTimeZoneOffsetInSeconds'));

deltaTime := SysTime.AdjustTimeInSeconds(timeNow,delta_days:=1);
OUTPUT(deltaTime,NAMED('AdjustTimeInSecondsOneDayForward'));

OUTPUT(SysTime.AdjustDate(theDate,delta_days:=1),NAMED('AdjustDate'));

*******************************************************************************/