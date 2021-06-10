# Program location definitions.
# --------------------------------------------------------------------------------------------
$MinecraftServerPath = "D:\Games\Minecraft\server"
$OverviewerPath = "D:\Games\Minecraft\overviewer\overviewer-0.16.12"
$WinSCPPath = "C:\Program Files (x86)\WinSCP"

# FUNCTIONS
# --------------------------------------------------------------------------------------------
function Start-Minecraft-And-Wait {
  Push-Location $MinecraftServerPath

  Start-Process javaw -ArgumentList "-Xms1024M", "-Xmx1024M", "-jar", "$MinecraftServerPath\server.jar" -RedirectStandardOutput stdout.txt -RedirectStandardError stderr.txt
  Start-Sleep -s 10
  $MinecraftServerProcessId = (Get-Process | Where-Object { $_.MainWindowTitle -like '*Minecraft server*' }).id
  Wait-Process -Id $MinecraftServerProcessId
}

function Start-Overviewer-And-Wait {
  $MinecraftServerProps = convertfrom-stringdata (get-content $MinecraftServerPath\server.properties -raw)
  $World = $MinecraftServerProps.'level-name'
  $WorldPath = "$MinecraftServerPath\$World"
  $WorldPathPythonFriendly = $WorldPath.replace('\','/')
  
  Push-Location $OverviewerPath
  Out-File -Encoding UTF8 -FilePath options.py
  Add-Content -Path options.py -Encoding UTF8 -Value "imgformat = `"jpg`"" # Default is 'png'
  Add-Content -Path options.py -Encoding UTF8 -Value "imgquality = `"50`"" # Default is 95
  Add-Content -Path options.py -Encoding UTF8 -Value "worlds[`"$World`"] = `"$WorldPathPythonFriendly`""
  Add-Content -Path options.py -Encoding UTF8 -Value "renders[`"normalrender`"] = {"
  Add-Content -Path options.py -Encoding UTF8 -Value "    `"world`": `"$World`","
  Add-Content -Path options.py -Encoding UTF8 -Value "    `"title`": `"Normal render of $World`","
  Add-Content -Path options.py -Encoding UTF8 -Value "}"
  Add-Content -Path options.py -Encoding UTF8 -Value "outputdir = `"../$World`"" -NoNewline
  
  Start-Process $OverviewerPath\overviewer.exe -ArgumentList "--config=options.py" -RedirectStandardOutput stdout.txt -RedirectStandardError stderr.txt
  $OverviewerProcessId = (Get-Process overviewer).id
  Wait-Process -Id $OverviewerProcessId
}

function Publish-Overviewer-Map-To-Web {
  # TODO: log to go to scripting folder
  Push-Location $OverviewerPath

  & "$WinSCPPath\WinSCP.com" `
    /log="WinSCP.log" /ini=nul `
    /command `
      "open ftp://nv0ir8pq76p1%40steve-chamberlain.co.uk:WbB%3F2%2Cxp8%7DR%60X.%3F%23@ftp.steve-chamberlain.co.uk/" `
      "synchronize remote -delete ..\$World /public_html/$World" `
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
Start-Overviewer-And-Wait
Publish-Overviewer-Map-To-Web