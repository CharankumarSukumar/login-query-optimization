# Usage: .\scripts\backup_restore.ps1 -Db login_db -User postgres
param([string]$Db="login_db",[string]$User="postgres",[string]$DbHost="localhost")
New-Item -ItemType Directory -Force backups | Out-Null
$file = "backups\$Db.dump"
pg_dump -h $DbHost -U $User -Fc -f $file $Db
createdb -h $DbHost -U $User "${Db}_restore"
pg_restore -h $DbHost -U $User -d "${Db}_restore" $file
psql -h $DbHost -U $User -d "${Db}_restore" -c "SELECT count(*) AS restored_users FROM users;"
