#!/bin/bash
# init-primary.sh

# echo "first line"
SA_PASSWORD='P@ssword1' # !!! CHANGE THIS !!!
SQLCMD="/opt/mssql-tools18/bin/sqlcmd"
SQLCMD_ARGS="-S localhost -U sa -P $SA_PASSWORD"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S.%2N') **init-primary.sh**  $1"
}

log "Installing iproute2 and iptables if missing..."
PKGS=()
command -v ip       &>/dev/null || PKGS+=(iproute2)
command -v iptables &>/dev/null || PKGS+=(iptables)
if [[ ${#PKGS[@]} -gt 0 ]]; then
    log "Installing: ${PKGS[*]}"
    apt-get update -qq && apt-get install -y -qq "${PKGS[@]}"
fi

log "Adding secondary IP 172.20.0.20 for AG Listener..."
if ip addr add 172.20.0.20/24 dev eth0; then
    log "Secondary IP 172.20.0.20 added successfully"
else
    log "ERROR: Failed to add secondary IP - is user: root and cap_add: NET_ADMIN set?"
    exit 1
fi

# Rewrite destination IP for port 63001: 172.20.0.10 -> 172.20.0.20 (no port change)
# This makes sys.dm_exec_connections show 172.20.0.20 for listener connections
if iptables -t nat -A PREROUTING -p tcp -d 172.20.0.10 --dport 63001 -j DNAT --to-destination 172.20.0.20:63001; then
    log "iptables DNAT rule added: 172.20.0.10:63001 -> 172.20.0.20:63001"
else
    log "ERROR: Failed to add iptables rule"
    exit 1
fi
log "Network setup complete. Listener will bind to 172.20.0.20:63001"

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
