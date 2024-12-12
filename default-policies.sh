#! /bin/bash

WAN='ens33'
LAN='ens36'

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

# Permitir consultas DNS de clientes externos
sudo iptables -A INPUT -p udp --dport 53 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 53 -j ACCEPT

# Permitir respostas DNS para clientes externos
sudo iptables -A OUTPUT -p udp --sport 53 -j ACCEPT
sudo iptables -A OUTPUT -p tcp --sport 53 -j ACCEPT

# Permitir consultas DNS do servidor para outros servidores DNS
sudo iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
sudo iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT

# Permitir respostas DNS de outros servidores para o servidor
sudo iptables -A INPUT -p udp --sport 53 -j ACCEPT
sudo iptables -A INPUT -p tcp --sport 53 -j ACCEPT

# Mantem o estado das conexoes da interface de loopback
iptables -I INPUT  -s 127.0.0.1  -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -I OUTPUT  -s 127.0.0.1  -m state --state RELATED,ESTABLISHED -j ACCEPT


# NAT MASQUERADE
iptables -A POSTROUTING -t nat -o $WAN -s $REDE_INTERNA -j MASQUERADE


# Libera todos os acesso originados de localhost para localhost
iptables -I INPUT -p tcp -s 127.0.0.1 -d 127.0.0.1  -j ACCEPT
iptables -I INPUT -p udp -s 127.0.0.1 -d 127.0.0.1  -j ACCEPT



###################### BLOQUEIOS REDE INTERNA PARA FORA ##################################

#BLOQUEIO AO SMTP PARA OS ENDEREÇOS INTERNOS
iptables -A FORWARD -i $LAN -p tcp -m iprange --src-range 10.10.10.15-10.10.10.18 -d 0/0 --dport 587 -j DROP


###################### REDE INTERNA PARA FORA ##################################

#LIBERA ICMP
iptables -A FORWARD -i $LAN -p icmp -s $REDE_INTERNA -d 0/0 -j ACCEPT
# Libera HTTPS
iptables -A FORWARD -i $LAN -p tcp -s $REDE_INTERNA -d 0/0 --dport 443 -j ACCEPT
#Libera HTTP
iptables -A FORWARD -i $LAN -p tcp -s $REDE_INTERNA -d 0/0 --dport 80 -j ACCEPT
#Libera SSH
iptables -A FORWARD -i $LAN -p tcp -s $REDE_INTERNA -d 0/0 --dport 22 -j ACCEPT
# Libera Mysql
iptables -A FORWARD -i $LAN -p tcp -s $REDE_INTERNA -d 0/0 --dport 3306 -j ACCEPT
# Libera Postgres
iptables -A FORWARD -i $LAN -p tcp -s $REDE_INTERNA -d 0/0 --dport 5432 -j ACCEPT
# Libera RDP
iptables -A FORWARD -i $LAN -p tcp -s $REDE_INTERNA -d 0/0 --dport 3389 -j ACCEPT
#libera telnet
iptables -A FORWARD -i $LAN -p tcp -s $REDE_INTERNA -d 0/0 --dport 23 -j ACCEPT
#Libera SMTP
iptables -A FORWARD -i $LAN -p tcp -s $REDE_INTERNA -d 0/0 --dport 587 -j ACCEPT
#libera POP3
iptables -A FORWARD -i $LAN -p tcp -s $REDE_INTERNA -d 0/0 --dport 110 -j ACCEPT
#Libera SNMP
iptables -A FORWARD -i $LAN -p udp -s $REDE_INTERNA -d 0/0 --dport 161 -j ACCEPT
#Libera NTP
iptables -A FORWARD -i $LAN -p udp -s $REDE_INTERNA -d 0/0 --dport 123 -j ACCEPT

####################################################################################
