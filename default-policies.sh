
#! /bin/bash

WAN='enp0s3'
LAN='enp0s8'

REDE_INTERNA='10.10.10.0/24'

# Ativa o roteamento
echo 1 > /proc/sys/net/ipv4/ip_forward

### Ativa Modulos
        /sbin/modprobe ip_conntrack
        /sbin/modprobe ip_conntrack_ftp
        /sbin/modprobe ip_nat_ftp
        /sbin/modprobe ipt_LOG

#### Limpa tabelas e configura defaults
        iptables -F -t filter
        iptables -F -t nat
        iptables -F -t mangle

        ## Delete chains nao defaults
        iptables -X
        iptables -X -t nat
        iptables -X -t mangle

        iptables -P INPUT  DROP -t filter
        iptables -P OUTPUT ACCEPT -t filter
        iptables -P FORWARD DROP -t filter

        iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT

# Libera acesso ao ICMP (Ping) nas interfaces LAN e WAN
iptables -A INPUT -i $WAN -p icmp -j ACCEPT
iptables -A INPUT -i $LAN -p icmp -j ACCEPT



# Libera SSH na porta 22
iptables -I INPUT -i $WAN -p tcp  -s 0/0 --dport 22 -j ACCEPT
iptables -I INPUT -i $LAN -p tcp  -s 0/0 --dport 22 -j ACCEPT

# Libera DNS (rede interna para externa)
iptables -I INPUT -i $LAN -p udp -s 0/0 --dport 53  -j ACCEPT



# Mantem o estado das conexoes da interface de loopback
iptables -I INPUT  -s 127.0.0.1  -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -I OUTPUT  -s 127.0.0.1  -m state --state RELATED,ESTABLISHED -j ACCEPT


# NAT MASQUERADE
iptables -A POSTROUTING -t nat -o $WAN -s $REDE_INTERNA -j MASQUERADE


# ICMP
iptables -A FORWARD -i $LAN -p icmp -s $REDE_INTERNA -d 0/0 -j ACCEPT
# DNS
iptables -A FORWARD -i $LAN -p udp -s $REDE_INTERNA -d 0/0 --dport 53 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT


# Libera todos os acesso originados de localhost para localhost
iptables -I INPUT -p tcp -s 127.0.0.1 -d 127.0.0.1  -j ACCEPT
iptables -I INPUT -p udp -s 127.0.0.1 -d 127.0.0.1  -j ACCEPT
