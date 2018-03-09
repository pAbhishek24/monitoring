For executing the Monitoring script on the windows server need to follow the below mentioned steps
STEP 1: Install Python 3.4 into the machine and dependncies
		 a. psutil 
		 b. cx_Oracle
STEP 2: Download and get the Instantclient_12_1 in python 34 folder and set the path
STEP 3: In Setup.bat need to update the below path as per our setup direcotories
		LOGSLOCATION=C:/Perf_Engineering/Logs/
		SCRIPTLOCATION=C:/Perf_Engineering/Scripts/
		DATALOCATION=C:/Perf_Engineering/Data/
STEP 4: To trigger the monitoring script need to provide the below info in command line
		a. NoUsers -- How many users test is triggered
		b. Execution Type -- Type of Execution(Ex ShipToShore or ShoreToShip)
		c. Additional Information - Any information regarding execution
		d. TESTDURATION - duration for monitoring the script in seconds
		e. DATATIME - wait time for capturing the records (time in seconds)
		e. PROCESSMONITOR - Process name to monitoring
		
		the command line to trigger will be like
		Ex:
		Setup.bat 2 HandheldDevice ShipToShoreRun1 50 2 FC DGS Resonline.exe
		
NOTE:If there is a space bwteen the process name then modify the batch file and in place of providing the name from command line provide the value in batch file at line 22

		
