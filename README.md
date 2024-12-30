# Purpose
As I was prototyping my stack I wanted to host my workloads within virtualbox for portabiity and ease of setup and administration.
My stack has deprecated this approach in favor of using proxmox to host an alpine container with docker compose and portainer.

# Usage
1. install VirtualBox
2. Use `Manage Advanced Sharing Settings` to enable File and printer sharing and for all networks enable password protected sharing
3. Use `Publish ISO` action from `vanderstack/Alpine-Docker-ISO/` to obtain Alpine docker server ISO
4. Create `config.json` from `config.example.json` with desired configuration
5. Run `create-docker-vm.ps1`
6. Run `create-user-and-share.ps1`
7. Build `docker-server-launcher.exe` using the Github Action `Build Docker Server Launcher`
8. Run `schedule-docker-server-launcher.ps1`

Todo:
add tailscale  
add obsidian  
add n8n  
create AI similar to do browser  
add portainer  
add retroarch  
add media server   
add cloudflare tunnel  
add guacamole  
add selenium  
add yt-download  
add torrent box?  
add android  
add url shortener  
add postrgeSQL admin  
add dosbox games like xeen or dark queen of krynn  
add AI stepmania  
add AMV server using AI to download all  
add wheresmything using AI to image recognition 
add flight tracker 
add more
