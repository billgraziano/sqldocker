#!/bin/bash
# init-secondary.sh

SA_PASSWORD='P@ssword1' # !!! CHANGE THIS !!!
SQLCMD="/opt/mssql-tools18/bin/sqlcmd"
SQLCMD_ARGS="-S localhost -U sa -P $SA_PASSWORD"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S.%2N') **init-secondary.sh**  $1"
}

log "Waiting for SQL Server on sqlnode2 to be ready..."
DBSTATUS=1
ERRCODE=1
i=0

while [[ $i -lt 60 ]]; do
    log "polling... attempt $i"
    i=$((i+1))
    DBSTATUS=$(/opt/mssql-tools18/bin/sqlcmd -C -t 5 -h -1 -U sa -P "$SA_PASSWORD" -Q "SET NOCOUNT ON; SELECT 1" 2>/dev/null | tr -d '[:space:]')
    ERRCODE=$?
    log "DBSTATUS=$DBSTATUS ERRCODE=$ERRCODE"
    if [[ "$ERRCODE" -eq 0 ]] && [[ "$DBSTATUS" -eq 1 ]]; then
        log "breaking..."
        break
    fi
    sleep 2
done
log "SQL Server on sqlnode2 is ready!"

log "Waiting for primary replica (sqlnode1) to be configured..."
while [ ! -f /certs/primary_ready.flag ]; do
    echo -n .
    sleep 5
done

log "Primary is ready! Configuring secondary replica..."
log "creating master key..."
# Create the master key
$SQLCMD $SQLCMD_ARGS -C -Q "CREATE MASTER KEY ENCRYPTION BY PASSWORD = '$SA_PASSWORD';"


# Create the certificate from the backup on the shared volume
log "create certificate..."
$SQLCMD $SQLCMD_ARGS -C -Q "CREATE CERTIFICATE ag_certificate FROM FILE = '/certs/ag_certificate.cer' WITH PRIVATE KEY (FILE = '/certs/ag_certificate.key', DECRYPTION BY PASSWORD = '$SA_PASSWORD');"

# Create the HADR endoint
log "create endpoint..."
$SQLCMD $SQLCMD_ARGS -C -Q "CREATE ENDPOINT [Hadr_endpoint] STATE=STARTED AS TCP (LISTENER_PORT = 5022, LISTENER_IP = ALL) FOR DATA_MIRRORING (ROLE = ALL, AUTHENTICATION = CERTIFICATE ag_certificate, ENCRYPTION = REQUIRED ALGORITHM AES);"

# Join the Availability Group
log "join endpoint..."
$SQLCMD $SQLCMD_ARGS -C -Q "ALTER AVAILABILITY GROUP [MyAG] JOIN WITH (CLUSTER_TYPE = NONE);"
$SQLCMD $SQLCMD_ARGS -C -Q "ALTER AVAILABILITY GROUP [MyAG] GRANT CREATE ANY DATABASE;"

log "Secondary setup complete."

# Keep the container running
# tail -f /dev/null
log "done."