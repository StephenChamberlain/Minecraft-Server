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
# Note: disable 'preview changes' in WinSCP GUI to push directly.
#& "$WinSCPPath\winscp.exe" www.steve-chamberlain.co.uk /synchronize "..\$World" "/public_html/$World"