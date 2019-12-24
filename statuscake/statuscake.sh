### Squared Reno Monitoring
### Sends message to status cake servers

### Install this script at /home/squared/2squared/ping/ping.sh

echo  `date` > /tmp/statuscake
echo `curl "https://push.statuscake.com/?PK=79051c3359f6a56&TestID=3280591&time=0"` >> /tmp/statuscake
