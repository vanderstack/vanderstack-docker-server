1. install VirtualBox
2. Use `vanderstack/Alpine-Docker-ISO/` to obtain Alpine docker server ISO
4. locate VBoxManage.exe
5. configure and run `create-docker-vm.ps1`
6. Use `Manage Advanced Sharing Settings` to enable network sharing
7. configure and run `create-user-and-share.ps1`
8. Build VM launcher `csc /target:winexe /out:vanderstack-docker-server.exe vanderstack-docker-server.cs`
9. launch VM

Todo:
add script to autostart vm
add tailscale
add obsidian
add n8n
