$Stmt = @"
SELECT  @@SERVERNAME AS [Host], 
	local_net_address, local_tcp_port
	--,client_net_address, client_tcp_port
FROM	sys.dm_exec_connections 
WHERE	session_id = @@SPID
"@
Invoke-SqlCmd -Server "D40,64001" -User sa -Password P@ssword1 -Query $Stmt -Encrypt Optional
Invoke-SqlCmd -Server "D40,64002" -User sa -Password P@ssword1 -Query $Stmt -Encrypt Optional
Invoke-SqlCmd -Server "D40,63001" -User sa -Password P@ssword1 -Query $Stmt -Encrypt Optional