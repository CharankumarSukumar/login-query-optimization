# Usage:  .\scripts\run_all.ps1 -Db login_db -User postgres
param([string]$Db="login_db",[string]$User="postgres",[string]$DbHost="localhost")
$ErrorActionPreference = "Stop"
New-Item -ItemType Directory -Force results | Out-Null
function Run($f){ psql -h $DbHost -U $User -d $Db -v ON_ERROR_STOP=1 -f $f }

Run sql\01_schema.sql
Run sql\02_seed.sql
Run sql\03_queries_baseline.sql  | Tee-Object results\baseline_explain.txt
Run sql\04_optimizations.sql
Run sql\05_queries_optimized.sql | Tee-Object results\optimized_explain.txt
Run sql\06_security.sql          | Tee-Object results\security_tests.txt

Write-Host "`n--- Load test (20 clients, 30 s each) ---"
foreach($t in "login_email","perm_join","perm_mv"){
  Write-Host "`n>> $t"
  pgbench -h $DbHost -U $User -d $Db -n -c 20 -j 4 -T 30 -f pgbench\$t.sql |
     Tee-Object results\pgbench_$t.txt
}
Write-Host "`nDone. See the results folder."
