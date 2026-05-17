# sqldocker
Create a SQL Server Contained Availability Group in Docker.  This is to support testing various applications against Contained Availability Groups.

Use `run.cmd` to create the images and run the container

Connecting
----------
sqlnode1 - port 64001
sqlnode2 - port 64002
MyAGListener - port 63001

From inside the container, we can run this `/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "P@ssword1" -Q "SELECT @@SERVERNAME" -No` to connect.

Limitations
-----------
* Failover doesn't work well.  Or it fails over but the the listener isn't exposed from the correct node.

Flow
----
* sqlnode1 is created 
    * run `init-primary.sh`
        * resets the `/certs` folder
        * runs `create-ag.sql`
            * Creates certs for the AG to communicate
            * Writes certs to the `/certs` folder
            * Creates the endpoint, CAG, and Listener
        * creates the `/certs/primary_ready.flag` file
* sqlnode2
    * run `init-secondary.sh`
        * wait on the `/certs/primary_ready.flag` file
        * loads the certificate
        * creates the endpoint and joins the AG

Notes
-----
* This will create a `certs` folder

Resources
---------
* https://sqlspark.com/2025/07/29/containers-101-for-dbas-5-building-customized-containers-for-sql-server/
* https://github.com/NaderSH/Container101forDBAs-SQLServer
