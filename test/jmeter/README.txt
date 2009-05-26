Testing the SDS with JMeter.

We've developed one test script, which can simulate:
 1) launching the Java client
   -- jnlp download
   -- config file download
   -- bundle file download
   -- otml file download
 2) shutting down the Java Client
   -- bundle file upload
   -- log bundle file upload
   
To use these tests:
  1) load the sds-startup.jmx file in jmeter
  2) edit the User Defined Variables in the Test Plan node to point to the correct SDS, urls for the bundle and log bundle posting, and locations of the data_files folder on your local system (note: if you run the tests on a remote machine, the folder will have to exist on the remote machine as well.)
  3) Edit the number of threads and loop count in the SDS thread group
  4) Make sure sysstat is logging at a granular level (optional, linux server only).
  4) Run the test.
  
The Aggregate Report listener will list basic statistics about the connections.
To get Server statistics, on Linux we used the sysstat group of tools. By default it runs just once every 10 minutes, so before you run the tests, make sure you run "sudo sh -c '/usr/lib/sa/sa1 1 3600 &'". This will make sysstat collect data once per second for the next hour. To view the collected statistics, use the sar command. See: http://pagesperso-orange.fr/sebastien.godard/
