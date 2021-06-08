# Program location definitions.
# --------------------------------------------------------------------------------------------
$MinecraftServerPath = "D:\Games\Minecraft\server"
$OverviewerPath = "D:\Games\Minecraft\overviewer\overviewer-0.16.12"
$WinSCPPath = "C:\Program Files (x86)\WinSCP"

# EXECUTE
# --------------------------------------------------------------------------------------------
# Start the server and wait until it exits.
Push-Location $MinecraftServerPath
Start-Process javaw -ArgumentList "-Xms1024M", "-Xmx1024M", "-jar", "$MinecraftServerPath\server.jar" -RedirectStandardOutput stdout.txt -RedirectStandardError stderr.txt
Start-Sleep -s 10
$MinecraftServerProcessId = (Get-Process | Where-Object { $_.MainWindowTitle -like '*Minecraft server*' }).id
Wait-Process -Id $MinecraftServerProcessId

$MinecraftServerProps = convertfrom-stringdata (get-content $MinecraftServerPath\server.properties -raw)
$World = $MinecraftServerProps.'level-name'
$WorldPath = "$MinecraftServerPath\$World"

# Generate overview HTML.
Push-Location $OverviewerPath
Start-Process $OverviewerPath\overviewer.exe -ArgumentList "$WorldPath", "..\$World"
$OverviewerProcessId = (Get-Process overviewer).id
Wait-Process -Id $OverviewerProcessId

# Sync it to the web.
& "$WinSCPPath\WinSCP.com" `
  /log="WinSCP.log" /ini=nul `
  /command `
    "open ftp://nv0ir8pq76p1%40steve-chamberlain.co.uk:WbB%3F2%2Cxp8%7DR%60X.%3F%23@ftp.steve-chamberlain.co.uk/" `
    "synchronize remote ..\$World /public_html/$World" `
    "exit"

$winscpResult = $LastExitCode
if ($winscpResult -eq 0)
{
  Write-Host "Success"
}
else
{
  Write-Host "Error"
}

exit $winscpResult