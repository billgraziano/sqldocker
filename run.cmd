docker compose down -v
if exist certs\* del /q certs\*
docker compose up -d
timeout /t 10

sqlcmd -S localhost,64001 -U sa -P P@ssword1 -Q "SELECT @@SERVERNAME"
sqlcmd -S localhost,64002 -U sa -P P@ssword1 -Q "SELECT @@SERVERNAME"

docker logs sqlnode1

