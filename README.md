1. install virtualbox
2. locate VBoxManage.exe
3. configure variables at the top of powershell script create-docker-vm.ps1
4. run powershell script create-docker-vm.ps1
5. launch VM
6. log into VM as root
7. initialize VM network connection
```sh
setup-interfaces
```
> Note: use defaults (eth0, dhcp, no manual config)
```sh
ifconfig eth0 up
udhcpc -i eth0
```
8. download installer script
```sh
wget https://github.com/vanderstack/vanderstack-docker-server/raw/main/install-alpine.sh
```
9. make installer script executable
```sh
chmod +x install-alpine.sh
```
10. run installer script
```sh
./install-alpine.sh
```
