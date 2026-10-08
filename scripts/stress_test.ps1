# Usage: .\scripts\stress_test.ps1 -Db login_db -User postgres
# Runs pgbench with more and more clients to find where throughput stops growing.
# max_connections is 100, so the top level stays at 90 clients.
param([string]$Db="login_db",[string]$User="postgres",[string]$DbHost="localhost")
New-Item -ItemType Directory -Force results | Out-Null
$out = "results\stress_test.txt"
"Stress test $(Get-Date)" | Out-File $out
foreach($t in "login_email","perm_mv"){
  foreach($c in 20,50,90){
    Write-Host "`n>> $t with $c clients (15 s)"
    "`n>> $t with $c clients (15 s)" | Out-File $out -Append
    pgbench -h $DbHost -U $User -d $Db -n -c $c -j 4 -T 15 -f pgbench\$t.sql |
      Select-String "number of clients|latency average|tps =|number of failed" |
      Tee-Object -FilePath $out -Append
  }
}
Write-Host "`nDone. See $out"
