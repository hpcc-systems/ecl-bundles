Calendar
===========

This bundle provides basic functionalities to work with date and time. 
All Two digit year representation can and will be assumed to fall between 1950-2049 

The following are the functionalities that are provided:

Three new types:

1. Date

2. Time

3. DateTime


Functions to get the current date and time

1. Now - returns the current local time in yyyy-mm-dd hh:mi:ss

2. UTCNow - returns the current UTC time in yyyy-mm-dd hh:mi:ss


Conversion Functions:

1. DtoDT(Date d) - Will convert a Date type to a DateTime type

2. TtoDT(Time t) - Will convert a Time type to a DateTime type

3. GetDatePart(DateTime dt) - Will get the date part of a datetime type. Returns a Date Type

4. GetTimePart(DateTime dt) - Will get the time part of a datetime type. Returns a Time Type


Funtions to infer date and time

1. CreateDFrom(UNSIGNED2 Year,UNSIGNED1 Month,UNSIGNED1 Day) - Accepts the parts and returns a Date type

2. CreateTFrom(UNSIGNED1 Hour,UNSIGNED1 Minute,UNSIGNED1 Second) - Accepts the parts and returns a Time type

3. CreateDTFrom(UNSIGNED2 Year,UNSIGNED1 Month,UNSIGNED1 Day,UNSIGNED1 Hour,UNSIGNED1 Minute,UNSIGNED1 Second) - Accepts the parts and returns a datetime type

4. CreateDTFromStr(STRING dt,STRING format = 'yyyy-mm-dd hh:mi:ss') - Accepts the custom formatted datetime string and the format and returns the datetime type  

5. CreateDFromStr(STRING d,STRING format = 'yyyy-mm-dd') - Accepts the custom formatted date string and the format and returns the date type

6. CreateTFromStr(STRING t,STRING format = 'hh:mi:ss') - Accepts the custom formatted time string and the format and returns the time type   


Functions to explode the date and time types to get its parts

1. IntrospectDT(DateTime dt) - Will return year, year2, month, monthname, dayof week, day, second, minute, hour, day of year, datepart and timepart

2. IntrospectD(Date dt) - Will return the same as above with the time components as 0 or empty

3. IntrospectT(Time t) - Will return the same as above with the date components as 0 or empty

4. GetDTRecord(DateTime dt) - Will return the same as above but as a single ROW


DateTime Comparison Functions

1. DatePartEnum := ENUM(UNSIGNED1,Seconds,Minutes,Hours,Days,Months,Years) - This will be used to specify the units for the below functions

2. DateDiff(DatePartEnum datePart, DateTime startDate, DateTime endDate) - Gives the difference between the two dates in the unit as specified in DatePartEnum

3. DateAdd(DatePartEnum datePart,INTEGER UnitsToAdd, DateTime dt) - Adds the specified units to the datetime and returns the new datetime.


DateTime Format Functions

1. FormatDT(DateTime dt,STRING Format = 'yyyy-mm-dd hh:mi:ss') - Takes a datetime type and the format and converts it to the specified format.

2. FormatD(Date dt, STRING Format = 'yyyy-mm-dd') - Takes a date type and the format and converts it to the specified format.

3. FormatT(Time t, STRING Format = 'hh:mi:ss') - Takes a time type and the format and converts it to the specified format.


-----------------------------------------------------------------------------------------------------------------------

Miscellaneous Functions:

NOTE:  These functions are extensively used inside the bundle. It's just available AS IS and is not part of the contract and 
may change in the future. You will most probably not need to use this and can get these values by using Introspect functions. 

1. IsLeapYear(Year) - Will return true if the year is a leap year

2. ConvertYr2ToYr4(Yr2) - Converts to 4 digit year

3. GetMonthNumber(String MonthName) - Will give the month number for the name

4. GetMonthName(UNSIGNED1 MonthNumber) - Will give the month name for the number

5. GetDayOfWeek(INTEGER4 GregorianDayCount)                        

6. GetDayOfYear(UNSIGNED2 Year,UNSIGNED1 Month,UNSIGNED1 Day)      

7. IsInvalidDate(UNSIGNED2 Year,UNSIGNED1 Month,UNSIGNED1 Day)    

8. IsInvalidTime(UNSIGNED1 Hour,UNSIGNED1 Minute,UNSIGNED1 Second)
