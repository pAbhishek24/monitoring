# windowsMonitoring
For executing the Monitoring script on the windows server need to follow the below mentioned steps<br>
STEP 1:Install Python 3.4 into the machine and dependncies
	<ul>
	<li>a. psutil</li>
	<li>b. cx_Oracle</li>
	</ul>
STEP 2:Download and get the Instantclient_12_1 in python 34 folder and set the path
STEP 3:In Setup.bat need to update the below path as per our setup direcotories
	<ul><li>LOGSLOCATION=C:/XXXXXXXXXX/Logs/</li>
	<li>SCRIPTLOCATION=C:/XXXXXXXXX/Scripts/</li>
	<li>DATALOCATION=C:/XXXXXXXXXXX/Data/</li></ul>
STEP 4:To trigger the monitoring script need to provide the below info in command linea. NoUsers -- How many users test is triggered
	<ul><li>Execution Type -- Type of Execution(Ex ShipToShore or ShoreToShip)</li>
	<li>Additional Information - Any information regarding execution</li>
	<li>TESTDURATION - duration for monitoring the script in seconds</li>
	<li>DATATIME - wait time for capturing the records (time in seconds)</li>
	<li>PROCESSMONITOR - Process name to monitoring</li></ul>
	
	command line to trigger will be like
	Ex:
		Setup.bat 2 HandheldDevice ShipToShoreRun1 50 2 FC DGS Resonline.exe

<b>NOTE:If there is a space bwteen the process name then modify the batch file and in place of providing the name from command line provide the value in batch file at line 22 </b>
