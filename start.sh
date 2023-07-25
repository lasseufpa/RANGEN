#!/bin/bash

num_ue=$1
tot_ues=$2

# Iniciar o comando ./nr-ue em segundo plano
./nr-ue -c ./config/uecfg${num_ue}.yaml -n ${tot_ues} &

sleep 40

# Loop para executar o ping em cada interface uesimtunX
for ((l=0; l<${tot_ues}; l++));
do
  interface="uesimtun$l"
  ping google.com -I ${interface} -i 0.05 -n &
done

# Manter o script em execução para que o contêiner não seja encerrado
tail -f /dev/null
