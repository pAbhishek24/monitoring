@ Echo Off
REM DATATIME and TESTDURATION are in seconds
REM +++++++++++++++++++++ Providing the information about location ++++++++
set LOGSLOCATION=C:/Perf_Engineering/Logs/
set SCRIPTLOCATION=C:/Perf_Engineering/Scripts/
set dateTime=%date:~7,2%-%date:~4,2%-%date:~10,4%_%time:~0,2%_%time:~3,2%_%time:~6,2%
set FILENAME=PerfCounters_%dateTime%
REM +++++++++++++++++++++ Creation of folders ++++++++
REM Today_date_no.of thread_new/old_specialcomments
set NoUsers=%1
set ExecutionType=%2
set AdditionalInformation=%3
set dateS=%date:~7,2%-%date:~4,2%-%date:~10,4%
echo %dateS%
set  DIRNAME=%dateS%_%NoUsers%_%ExecutionType%_%AdditionalInformation%
echo DirecotryName : %DIRNAME%
mkdir "%LOGSLOCATION%%DIRNAME%"

REM +++++++++++++++++++++ Execution Information ++++++++
set DATATIME=%5
set TESTDURATION=%4
set PROCESSMONITOR=%6
echo +++ Message : Executing the Python script
%SCRIPTLOCATION%PerfCollector.py
