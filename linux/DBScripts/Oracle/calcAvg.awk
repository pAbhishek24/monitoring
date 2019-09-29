BEGIN {sum1=0; sum2=0; count=0}
{
#   print $1+$2;
   if ($1+$2 < 95)
	{	
#	print $1+$2;
	sum1=sum1+$1;
	sum2=sum2+$2;
	count=count+1;
	}
}
END {
avg1=sum1/count;
avg2=sum2/count;
print "\nUtil=",100-(avg1+avg2), "\nIdle=",avg1, "\nIOWait=",avg2,"\nCount=",count; }

