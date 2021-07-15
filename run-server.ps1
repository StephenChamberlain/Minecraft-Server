# Program location definitions.
# --------------------------------------------------------------------------------------------
$MinecraftServerPath = "D:\Games\Minecraft\server"
$MinecraftServerProps = convertfrom-stringdata (get-content $MinecraftServerPath\server.properties -raw)
$World = $MinecraftServerProps.'level-name'
$WorldPath = "$MinecraftServerPath\$World"
$WorldPathPythonFriendly = $WorldPath.replace('\','/')
$OverviewerPath = "D:\Games\Minecraft\overviewer\overviewer-0.16.12"
$WinSCPPath = "C:\Program Files (x86)\WinSCP"
$ScriptPath = $MyInvocation.MyCommand.Path
$WorkingDirectory = Split-Path $scriptpath
$BackupDirectory = "D:\Games\Minecraft\server\world-backups"
$LogDirectory = "$WorkingDirectory\logs"

# TODO: Check if there is a new version of minecraft server and download if available.
# TODO: Make logs dir if not present, otherwise logs not generated.
# TODO: Fixed IPs for routers

# FUNCTIONS
# --------------------------------------------------------------------------------------------
function Start-Minecraft-And-Wait {
  Push-Location $MinecraftServerPath

  Start-Process javaw  `
  -ArgumentList "-Xms1024M", "-Xmx1024M", "-jar", "$MinecraftServerPath\server.jar"  `
  -RedirectStandardOutput $LogDirectory\minecraft-stdout.txt  `
  -RedirectStandardError  $LogDirectory\minecraft-stderr.txt

  Start-Sleep -s 20
  # WARNING: if you create a shortcut link to start this script, be sure to name it something other than "Minecraft server", otherwise this
  # command will find the powershell prompt and not the Minecraft server GUI window!
  $MinecraftServerProcessId = (Get-Process | Where-Object { $_.MainWindowTitle -like '*Minecraft server*' }).id
  Wait-Process -Id $MinecraftServerProcessId
}

function Backup-Minecraft {
  $TimeStamp = Get-Date -Format "MM-dd-yyyy_HH-mm"
  $compress = @{
    Path = "$WorldPath"
    CompressionLevel = "Fastest"
    DestinationPath = "$BackupDirectory\$World-$TimeStamp.zip"
  }
  Compress-Archive @compress
}

function Start-Overviewer-And-Wait {
  Push-Location $OverviewerPath

  Out-File -Encoding UTF8 -FilePath options.py
  Add-Content -Path options.py -Encoding UTF8 -Value "imgformat = `"jpg`"" # Default is 'png'
  Add-Content -Path options.py -Encoding UTF8 -Value "imgquality = `"50`"" # Default is 95
  Add-Content -Path options.py -Encoding UTF8 -Value "worlds[`"$World`"] = `"$WorldPathPythonFriendly`""
  Add-Content -Path options.py -Encoding UTF8 -Value "renders[`"overworld`"] = {"
  Add-Content -Path options.py -Encoding UTF8 -Value "    `"world`": `"$World`","
  Add-Content -Path options.py -Encoding UTF8 -Value "    `"title`": `"Overworld`","
  Add-Content -Path options.py -Encoding UTF8 -Value "    `"rendermode`": `"smooth_lighting`","
  Add-Content -Path options.py -Encoding UTF8 -Value "    `"dimension`": `"overworld`","
  Add-Content -Path options.py -Encoding UTF8 -Value "    `"crop`": (-350, -350, 350, 200),"
  Add-Content -Path options.py -Encoding UTF8 -Value "}"
  Add-Content -Path options.py -Encoding UTF8 -Value "renders[`"nether`"] = {"
  Add-Content -Path options.py -Encoding UTF8 -Value "    `"world`": `"$World`","
  Add-Content -Path options.py -Encoding UTF8 -Value "    `"title`": `"Nether`","
  Add-Content -Path options.py -Encoding UTF8 -Value "    `"rendermode`": `"nether_smooth_lighting`","
  Add-Content -Path options.py -Encoding UTF8 -Value "    `"dimension`": `"nether`","
  Add-Content -Path options.py -Encoding UTF8 -Value "    `"crop`": (-350, -350, 350, 200),"
  Add-Content -Path options.py -Encoding UTF8 -Value "}"  
  Add-Content -Path options.py -Encoding UTF8 -Value "outputdir = `"../$World`"" -NoNewline
  
  Start-Process $OverviewerPath\overviewer.exe  `
  -ArgumentList "--config=options.py"  `
  -RedirectStandardOutput $LogDirectory\overviewer-stdout.txt  `
  -RedirectStandardError  $LogDirectory\overviewer-stderr.txt
  $OverviewerProcessId = (Get-Process overviewer).id
  Wait-Process -Id $OverviewerProcessId
}

function Publish-Overviewer-Map-To-Web {
  & "$WinSCPPath\WinSCP.com" `
    /log="$LogDirectory\WinSCP.log" /ini=nul `
    /command `
      "open ftp://overviewer%40steve-chamberlain.co.uk:jtxhCWnjeknggBFZEri8@ftp.steve-chamberlain.co.uk/" `
      "synchronize remote $OverviewerPath/../$World ." `
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
}

# EXECUTE
# --------------------------------------------------------------------------------------------
Start-Minecraft-And-Wait
Backup-Minecraft
Start-Overviewer-And-Wait
Publish-Overviewer-Map-To-Web
exit