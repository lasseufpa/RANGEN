#!/bin/bash

number_ues=$1
number_gnb=$2
nome_arquivo="docker-compose-setup.yaml"
imsi=208930000000000
imsi_f=208930000000000
link_gnb="gnb.free5gc.org"


touch ./ueransim/start.sh

start_file="
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
"

echo "$start_file" >> ./ueransim/start.sh

#copia o conteúdo do arquivo build para o setuup para garantir um esado inicial conhecido
cp docker-compose-build.yaml docker-compose-setup.yaml

#a definição de redes para ser add no final do arquivo de setup
final="
networks:
  privnet:
    ipam:
      driver: default
      config:
        - subnet: 10.100.200.0/24
    driver_opts:
      com.docker.network.bridge.name: br-free5gc

volumes:
  dbdata:
"

#bloco que add um contâiner ppara cada pack de gnb+ues
for ((i=0; i<$number_gnb; i++));
do
    service_block="
  ueransim$i:
    container_name: ueransim$i
    build:
      context: ./ueransim
    volumes:
      - ./config/gnbcfg$i.yaml:/ueransim/config/gnbcfg$i.yaml
      - ./config/uecfg$i.yaml:/ueransim/config/uecfg$i.yaml
      - ./config/gnbcfg.yaml:/ueransim/config/gnbcfg.yaml
      - ./config/uecfg.yaml:/ueransim/config/uecfg.yaml
    cap_add:
      - NET_ADMIN
    devices:
      - "/dev/net/tun"
    networks:
      privnet:
        aliases:
          - ue$i.free5gc.org
    depends_on:
      - free5gc-amf
      - free5gc-upf
    command: ./start.sh $i $number_ues

  ueransim-gnb$i:
    container_name: ueransim-gnb$i
    build:
      context: ./ueransim
    volumes:
      - ./config/gnbcfg$i.yaml:/ueransim/config/gnbcfg$i.yaml
      - ./config/gnbcfg.yaml:/ueransim/config/gnbcfg.yamll
    cap_add:
      - NET_ADMIN
    devices:
      - "/dev/net/tun"
    networks:
      privnet:
        aliases:
          - gnb$i.free5gc.org
    depends_on:
      - free5gc-amf
      - free5gc-upf
    command: ./nr-gnb -c ./config/gnbcfg$i.yaml &
"
#add o bloco acima no docker compose
echo "$service_block" >> "$nome_arquivo"

#cria um arquivo uecfgx com base no arquivo uecfg que começa no imsi de final 0
#sendo x o num atual da gnb
cat config/uecfg.yaml > config/uecfg$i.yaml

#calcula o imsi com base no arquivo de configuracão(num da gnb)
sed -i "s#$imsi#$imsi_f#g" config/uecfg$i.yaml
imsi_f=$(( $number_ues * ($i + 1) + $imsi ))

#troca o ip da rede no arquivo da ue com base na gnb
sed -i "s#$link_gnb#gnb$i.free5gc.org#g" config/uecfg$i.yaml

#cria um arquivo gnbcfgx com base no arquivo gnbcfg que começa com ip gnb.free5gc.org
#sendo x o num atual da gnb
cat config/gnbcfg.yaml > config/gnbcfg$i.yaml

#troca o ip da rede no arquivo da gnb com base no num da gnb
sed -i "s#$link_gnb#gnb$i.free5gc.org#g" config/gnbcfg$i.yaml

done

#adciona as configurações de rede no final do arquivo
echo "$final" >> "$nome_arquivo"

#buid os containers do ueransim
for ((j=0; j<$number_gnb; j++));
do
docker compose -f docker-compose-setup.yaml build ueransim$j
docker compose -f docker-compose-setup.yaml build ueransim-gnb$j
done

sleep 5

docker compose -f docker-compose-setup.yaml up


#deleta os arquivos de config das ues

for ((k=0; k< $number_gnb; k++));
do

file_name="config/uecfg$k.yaml"
rm -rf "${file_name}"

file_name="config/gnbcfg$k.yaml"
rm -rf "${file_name}"    
done

#sed -i "s#$1#numero_ues#g" ueransim/start.sh
