############## BOILER PLATE
#	Author     : Abhishek
# 	Date	   : Oct 28, 2016
#	Reviewed BY:
# 	Revised ON : 
# 	Revised BY : 
# 	Description: 
#		1. This script is intended to capture the performance matrices related to CPU memory IO and network and kernel parameters
#		2. Data should be captured after every 2 seconds or more till the end of the execution - script are intended to execute duration based
#	Next Feature:
#		1. Remote Execution
#		2. Write data into database
#######################################################################
# module import
import os
import sys
import csv 
import psutil
import time
import datetime
import socket
from socket import AF_INET, SOCK_STREAM, SOCK_DGRAM



##################
# Main Starts here
#####

# Variable
ErrorFound = False
counter = 0
now = datetime.datetime.now()
cpuStr = "CPU(%) = "
memVir = "percent(V) = "
memSwap= "percent(S) = "
totalCPU = 0.0
totalVMem = 0.0
totalSMem = 0.0
pThrNum = 0.0
totalpCPU = 0.0
totalpMem = 0.0
totalpHandles = 0.0
pName = None

# Reading environemnt variable
dataCounter = os.environ.get("DATATIME")
testDuration = os.environ.get("TESTDURATION")
logFile = os.environ.get("LOGSLOCATION")
fileName = os.environ.get("FILENAME")
directoryName = os.environ.get("DIRNAME")
processName = os.environ.get("PROCESSMONITOR")
#testName=os.environ.get("TESTNAME")
 
#@profile
def dataWrite(n,m):
	#print("Directory Name",directoryName)
	with open(logFile + "/" + directoryName + "/"+ fileName + ".txt", "a") as perfStats:
		perfStats.write("=======================================================\n")
		perfStats.write("++++ ITERATION : " + str(counter) + " +++++++++++ \n")
		perfStats.write("TIME="+str(datetime.datetime.now()) +" "+ m + "\n")
		perfStats.write("=======================================================\n")
		if m == " CPU UTILIZATION (Per CORE, Interval = 1) ":
			perfStats.write("CPU(PerCore) = " + str(n) + "\n")
		elif m == " CPU TIMES (Per CORE in min) ":
			for name in n._fields:
				value = getattr(n,name)
				value = value / 60
				perfStats.write(str(name) + " = " + str(value) + "\n")
		elif m == "CPU Utilization":
			perfStats.write("CPU(%) = "+str(n)+"\n")
		elif m == "DISK IO (MB)":
			for name in n._fields:
				value = getattr(n,name)
				value = value / (1024*1024)
		else:
			for name in n._fields:
				value = getattr(n,name)
				if m == " NETWORK STATISTICS (I/O Counters - MB) ":
					value = getattr(n,name)
					value = value / (1024*1024)
					perfStats.write(str(name) + " = " + str(value) + "\n")
				elif m == " VIRTUAL MEMORY (GB) ":
					if name != 'percent':
						value = value / 1073741824
						name = name + "(V)"
					if name == 'percent':
						name = name + "(V)"
					memData = str(name) + " = " + str(value) + "\n"
					perfStats.write(memData)
				elif m == " SWAP MEMORY (GB) ":
					if name != 'percent':
						value = value / 1073741824
						name = name + "(S)"
					if name == 'percent':
						name = name + "(S)"
					memData = str(name) + " = " + str(value) + "\n"
					perfStats.write(memData)
					
# Display data on console
def dataDisplay(cpu,mem):
	print("========== Resource Utilization ===========")
	print("CPU = ",cpu )
	for attName in mem._fields:
		value =getattr(mem,attName)
		if attName != 'percent':
			value = value / 1073741824
		data = str(attName) + " = " + str(value)
		print(data)
	print("===========================================")

# Function to write Process informaiton:
def writeProcessInfo(counter,pName,pThrNum,pThread,pCPU,pMem,pHandles):
	global totalpCPU
	global totalpMem
	global totalpHandles
	global now
	with open(logFile + "/" + directoryName + "/"+ fileName + "_ProcessInformation.txt", "a") as processStats:
		processStats.write("----------------------------------------------------------------------\n")
		proInfo = "TIME="+str(datetime.datetime.now()) +" Iteration = " + str(counter) + " || " + "ProcessName=" + str(pName) + " || " + "NoThreads=" + str(pThrNum) + " || " + "CPU(%)=" + str(pCPU)+ " || " + "MEM(%)=" + str(pMem) + " || " + "HANDLES=" + str(pHandles) +"\n"
		processStats.write(proInfo)
		processStats.write("----------------------------------------------------------------------\n")
		processStats.write("ThreadID\t UserTime\t SYSTime\t TotalCPU\n")
		for th in pThread:
			processStats.write(str(round(th[0],2)) + "\t\t "+ str(round(th[1],2)) + "\t\t "+ str(round(th[2],2)) + "\t\t " + str(round((th[1]+th[2]),2)) + "\n")
			#processStats.write(str(th))
		processStats.write("----------------------------------------------------------------------\n")
		totalpCPU += pCPU
		totalpMem += pMem
		totalpHandles +=pHandles
		
		
		
# Function to Parse the data file and create a master file    
def masterData(filePath,readFile,counter):
	global totalCPU
	global totalVMem
	global totalSMem
	global now
	global pName
	global pThrNum
	global totalpCPU
	global totalpMem
	global totalpHandles
	global testName
	
	with open(filePath + readFile + ".txt","r") as modFile:
		for lines in modFile:
			if cpuStr in lines:
				a=lines[9:].strip()
				totalCPU += float(a)
			if memVir in lines:
				b=lines[13:].strip()
				totalVMem += float(b)
			if memSwap in lines:
				c=lines[13:].strip()
				totalSMem += float(c)
	avgCPU = (totalCPU/counter)
	avgVirMem = (totalSMem/counter)
	avgSwapMem = (totalVMem/counter)
	
	# Thread Information Average
	pCPUAVG = (totalpCPU/counter)
	pMEMAVG = (totalpMem/counter)
	pHANDLESAVG = (totalpHandles/counter)
	
	print("Average CPU = ",avgCPU)
	print("Average SwapMemory = ",avgVirMem)
	print("Average VirtualMemory = ",avgSwapMem)
		
	with open(logFile + "MasterInformation.txt","a") as mastFile:
		#data1 = str(datetime.datetime.now()) + "TestName=" + str(testname) + " || Total Iteration=" + str(counter) + " || AVG CPU(%)=" + str(round(avgCPU,2)) + " || AVG VirtualMemory(%)=" + str(round(avgVirMem,2)) + " || AVG SwapMemory(%)=" + str(round(avgSwapMem,2)) + " || " + " ProcessName=" + pName + " || " + " TotalThreads=" + str(pThrNum) + " || " + " ThreadCPU(%)=" + str(round(pCPUAVG,2)) + " || " + " ThreadMEM(%)=" + str(round(pMEMAVG,2)) +" || " + " HANDLES=" + str(round(pHANDLESAVG,2)) +  "\n"
		data1 = str(datetime.datetime.now()) +" || Total Iteration=" + str(counter) + " || AVG CPU(%)=" + str(round(avgCPU,2)) + " || AVG VirtualMemory(%)=" + str(round(avgVirMem,2)) + " || AVG SwapMemory(%)=" + str(round(avgSwapMem,2)) + " || " + " ProcessName=" + pName + " || " + " TotalThreads=" + str(pThrNum) + " || " + " ThreadCPU(%)=" + str(round(pCPUAVG,2)) + " || " + " ThreadMEM(%)=" + str(round(pMEMAVG,2)) +" || " + " HANDLES=" + str(round(pHANDLESAVG,2)) +  "\n"
		mastFile.write(data1)
		
# Validating Input Data
if dataCounter is None:
	print("!!! Warning : Time delay to capture the statics is not provided DATATIME : ",dataCounter)
	ErrorFound = True
if testDuration is None:
	print("!!! Error : Test Execution duration has not provided TESTDURATION : ",testDuration)
	ErrorFpund = True
if processName is None:
	print("!!! Error : Process Name is not proided ")
	ErrorFound = True
else:
	currentTime = time.time()
	# Getting all the process information
	for proc in psutil.process_iter():
		pinfo = proc.as_dict(attrs=['pid','name'])
		if pinfo['name']== '"'+str(processName)+'""': #"FC DGS Resonline.exe"":	
			pNum=pinfo['pid']
	# Creating Object for Process Class and passing to the Process Class
	p = psutil.Process(pid=pNum)
	while (time.time() - currentTime) <= float(testDuration):
		counter += 1
		cpuVar = psutil.cpu_times(percpu=True)
		for data in cpuVar:
			dataWrite(data," CPU TIMES (Per CORE in min) ")
		cpuPerCore = psutil.cpu_percent(interval=1,percpu = True)
		for each_data in cpuPerCore:
			dataWrite(each_data," CPU UTILIZATION (Per CORE, Interval = 1) ")
		# Capturing CPU Stats:
		dataWrite(psutil.cpu_stats()," CPU STATISTICS ")
		# Capturing Virtual Memory
		dataWrite(psutil.virtual_memory()," VIRTUAL MEMORY (GB) ")
		# Capturing Swap Memory
		dataWrite(psutil.swap_memory()," SWAP MEMORY (GB) ")
		# Dist I/O statistics
		#dataWrite(psutil.disk_io_counters(perdisk=False),"DISK IO (MMB)")
		# capturing the network statistics
		dataWrite(psutil.net_io_counters(pernic=False)," NETWORK STATISTICS (I/O Counters - MB) ")
		# Display CPU and Memory on console
		cpuUtliz = psutil.cpu_percent(interval=1,percpu = False)
		dataWrite(cpuUtliz,"CPU Utilization")
		memoryUtliz = psutil.virtual_memory()
		dataDisplay(cpuUtliz,memoryUtliz)
		# Capturing the ProcessInformaiton
		pName = p.name()
		pThrNum = round((p.num_threads()),2)   # Number of threads
		pThread = p.threads()		   # Thread information
		pCPU = round((p.cpu_percent(interval = 1)/psutil.cpu_count()),2) # CPU consumption of process
		pMem = round((p.memory_percent()),2)   # Percentage comsumption of memory 
		pHandles = round((p.num_handles()),2)		 # Number of handles of the process
		writeProcessInfo(counter,pName,pThrNum,pThread,pCPU,pMem,pHandles)
		# collecting counter after every defined seconds
		time.sleep(int(dataCounter))
	masterData(logFile + directoryName + "/",fileName,counter)
		
if ErrorFound:
	print("!!! Error : Encountered Error, exiting the script execution ")
	sys.exit()
else:
	print("### Sucess : Script execution complted sucessfully ")
	print("### Exiting Script ")