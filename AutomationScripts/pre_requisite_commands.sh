#pwd
#ls -la

sudo apt-get install attr -y
sudo apt-get install glusterfs-client -y
service glusterfs-server stop


mount.glusterfs
modinfo dm_snapshot
modinfo dm_mirror
modinfo dm_thin_pool
modprobe dm_snapshot
modprobe dm_mirror
modprobe dm_thin_pool
lsmod | grep dm

sudo apt-get install iptables-persistent -y

sudo iptables -P FORWARD ACCEPT 
iptables -A FORWARD -i cni0 -j ACCEPT
iptables -A FORWARD -o cni0 -j ACCEPT

sudo iptables -P FORWARD ACCEPT 
iptables -A FORWARD -i tunl0 -j ACCEPT
iptables -A FORWARD -o tunl0 -j ACCEPT


iptables -N HEKETI
iptables -A HEKETI -p tcp -m state --state NEW -m tcp --dport 24007 -j ACCEPT
iptables -A HEKETI -p tcp -m state --state NEW -m tcp --dport 24008 -j ACCEPT
iptables -A HEKETI -p tcp -m state --state NEW -m tcp --dport 2222 -j ACCEPT
iptables -A HEKETI -p tcp -m state --state NEW -m multiport --dports 49152:49251 -j ACCEPT

sudo bash -c "iptables-save > /etc/iptables.rules"
sudo iptables-save > /etc/iptables/rules.v4
sudo iptables-save > /etc/iptables/rules.v6
iptables-save | grep -i forward

