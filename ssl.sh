#!/bin/bash
declare -A cor=( [0]="\033[1;37m" [1]="\033[1;34m" [2]="\033[1;31m" [3]="\033[1;33m" [4]="\033[1;32m" )
SCPfrm="/etc/ger-frm" && [[ ! -d ${SCPfrm} ]] && exit
SCPinst="/etc/ger-inst" && [[ ! -d ${SCPinst} ]] && exit
API_TRANS="aHR0cHM6Ly93d3cuZHJvcGJveC5jb20vcy9sNmlxZjV4anRqbXBkeDUvdHJhbnM/ZGw9MA=="
SUB_DOM='base64 -d'
wget -O /usr/bin/trans $(echo $API_TRANS|$SUB_DOM) &> /dev/null
mportas () {
unset portas
portas_var=$(lsof -V -i tcp -P -n | grep -v "ESTABLISHED" |grep -v "COMMAND" | grep "LISTEN")
while read port; do
var1=$(echo $port | awk '{print $1}') && var2=$(echo $port | awk '{print $9}' | awk -F ":" '{print $2}')
[[ "$(echo -e $portas|grep "$var1 $var2")" ]] || portas+="$var1 $var2\n"
done <<< "$portas_var"
i=1
echo -e "$portas"
}
ssl_stunel () {
[[ $(mportas|grep stunnel4|head -1) ]] && {
msg -ama " $(fun_trans "Parando Stunnel")"
msg -bar
fun_bar "apt-get purge stunnel4 -y"
msg -bar
msg -ama " $(fun_trans "Parado Con Exito!")"
msg -bar
return 0
}
msg -azu " $(fun_trans "SSL Stunnel")"
msg -bar
msg -ama " $(fun_trans "Seleccione un puerto de redireccionamiento interno")"
msg -ama " $(fun_trans "Es decir un puerto en su servidor para SSL")"
msg -ama " $(fun_trans "Ejemplo Dropbear OpenSSH ShadowSocks OpenVPN etc")"
msg -bar
         while true; do
         echo -ne "\033[1;37m"
         read -p " Local-Port: " portx
         if [[ ! -z $portx ]]; then
             if [[ $(echo $portx|grep [0-9]) ]]; then
                [[ $(mportas|grep $portx|head -1) ]] && break || echo -e "\033[1;31m $(fun_trans "Porta Invalida")"
             fi
         fi
         done
msg -bar
DPORT="$(mportas|grep $portx|awk '{print $2}'|head -1)"
msg -ama " $(fun_trans "Ahora tenemos que saber qué puerto el SSL escuchará")"
msg -bar
    while true; do
    read -p " Listen-SSL: " SSLPORT
    [[ $(mportas|grep -w "$SSLPORT") ]] || break
    echo -e "\033[1;33m $(fun_trans "esta Porta Ja esta em Uso")"
    unset SSLPORT
    done
msg -bar
msg -ama " $(fun_trans "Instalando SSL")"
msg -bar
fun_bar "apt-get install stunnel4 -y"
echo -e "cert = /etc/stunnel/stunnel.pem\nclient = no\ndelay = yes\nciphers = ALL\nsslVersion = ALL\nsocket = a:SO_REUSEADDR=1\nsocket = l:TCP_NODELAY=1\nsocket = r:TCP_NODELAY=1\nsocket = l:SO_KEEPALIVE=1\nsocket = r:SO_KEEPALIVE=1\n\n[ssh]\nconnect = 127.0.0.1:${DPORT}\naccept = ${SSLPORT}" > /etc/stunnel/stunnel.conf
openssl genrsa -out key.pem 2048 > /dev/null 2>&1
(echo br; echo br; echo uss; echo speed; echo adm; echo ultimate; echo @admultimate)|openssl req -new -x509 -key key.pem -out cert.pem -days 1095 > /dev/null 2>&1
cat key.pem cert.pem >> /etc/stunnel/stunnel.pem
sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
service stunnel4 restart > /dev/null 2>&1
msg -bar
msg -ama " $(fun_trans "INSTALADO CON EXITO")"
msg -bar
return 0
}
ssl_stunel