#!/bin/bash
# init-primary.sh

# echo "first line"
SA_PASSWORD='P@ssword1' # !!! CHANGE THIS !!!
SQLCMD="/opt/mssql-tools18/bin/sqlcmd"
SQLCMD_ARGS="-S localhost -U sa -P $SA_PASSWORD"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S.%2N') **init-primary.sh**  $1"
}

log "Waiting for SQL Server on sqlnode1 to be ready..."
# uname -r
# uname -a 
# lsb_release -a



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

log "SQL Server on sqlnode1 is ready!"
log "Configuring Primary Replica and AG!"

rm -f /certs/ag_certificate.cer /certs/ag_certificate.key /certs/primary_ready.flag


# Run the consolidated setup script
$SQLCMD $SQLCMD_ARGS -i /usr/src/app/create-ag.sql -C

# Create a flag file to signal that the primary is configured and cert is ready
touch /certs/primary_ready.flag
log "Primary setup complete. Flag file created."

# Keep the container running
# tail -f /dev/null
log "done."
