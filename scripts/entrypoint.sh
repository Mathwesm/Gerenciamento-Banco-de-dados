#!/bin/bash
wait_time=15s

# wait for SQL Server to come up
echo importing data will start in $wait_time...
sleep $wait_time
echo executing script...

# run scripts to populate by Bulk insert all these test data
/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'Cc202505!' -N -C -i /scripts/init.sql
