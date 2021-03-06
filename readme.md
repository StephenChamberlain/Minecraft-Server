Script to do the following:

- Run Minecraft server.
- Once the server stops:
    - Create a zipped, timestamped backup.
    - Generate a world overview/isometric map with Overviewer (https://overviewer.org/).
    - Push the overview to the web (http://www.steve-chamberlain.co.uk/discordia).

## Instructions
Check out to [your Minecraft installation path]\scripting, where server and overviewer are sibling folders to 'scripting':

![Folder structure](/folder-structure.png?raw=true)  

## Dependencies
Relies on: 
- Java on the Windows PATH.
- Overviewer (https://docs.overviewer.org/en/latest/).
- WinSCP.
