# SQL Server Availability Group in Docker
Create a SQL Server Contained Availability Group in Docker.  This is to support testing various applications against Contained Availability Groups.

Use `run.cmd` to create the images and run the container

Connecting
----------
From outside Docker, connect using the following ports:

| Target        | Port  |
|-------------- | ----- |
| sqlnode1      | 64001 |
| sqlnode2      | 64002 |
| MyAGListener  | 63001 |

From inside the container, we can run this `/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "P@ssword1" -Q "SELECT @@SERVERNAME" -No` to connect.

The result of running `Test-Connections.ps1` on my machine is:
```
Host     local_net_address local_tcp_port
----     ----------------- --------------
sqlnode1 172.20.0.10                 1433
sqlnode2 172.20.0.11                 1433
sqlnode1 172.20.0.20                63001
```

Limitations
-----------
* Failover doesn't work and isn't really tested.  Or it fails over but the the listener isn't exposed from the correct node.  This isn't really why it was built.
* The networking and assigning a specific IP to the AG was cobbled together by an LLM.  It seems to work but I don't understand it.

Flow
----
* sqlnode1 is created and runs `init-primary.sh`
    * resets the `/certs` folder
    * runs `create-ag.sql`
        * Creates certs for the AG to communicate
        * Writes certs to the `/certs` folder
        * Creates the endpoint, CAG, and Listener
    * creates the `/certs/primary_ready.flag` file
* sqlnode2 and runs `init-secondary.sh`
    * wait on the `/certs/primary_ready.flag` file
    * loads the certificate
    * creates the endpoint and joins the AG

Notes
-----
* This will create a `certs` folder in this folder

Resources
---------
* https://sqlspark.com/2025/07/29/containers-101-for-dbas-5-building-customized-containers-for-sql-server/
* https://github.com/NaderSH/Container101forDBAs-SQLServer
