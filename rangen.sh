#!/bin/bash

# Input parameters for the number of UEs and gNBs
number_ues=$1
number_gnb=$2


nome_arquivo="docker-compose-setup.yaml"
imsi=208930000000000
imsi_f=208930000000000
link_gnb="gnb.free5gc.org"

# Copy the contents of the base file to the setup file to ensure a known initial state
cp docker-compose-base.yaml docker-compose-setup.yaml

# Network definitions to be added at the end of the setup file
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

# Loop to add a container for each gNB+UEs pack
for ((i=0; i<$number_gnb; i++));
do
    # Block that defines the service for each UE and gNB
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
# Append the service block to the docker-compose file
echo "$service_block" >> "$nome_arquivo"

# Create a uecfgx file based on the uecfg file starting with an imsi of 0
# Here x is the current number of gNB
cat config/uecfg.yaml > config/uecfg$i.yaml

# Calculate the imsi based on the configuration file (number of gNB)
sed -i "s#$imsi#$imsi_f#g" config/uecfg$i.yaml
imsi_f=$(( $number_ues * ($i + 1) + $imsi ))

# Change the network IP in the UE file based on the gNB
sed -i "s#$link_gnb#gnb$i.free5gc.org#g" config/uecfg$i.yaml

# Create a gnbcfgx file based on the gnbcfg file starting with IP gnb.free5gc.org
# Here x is the current number of gNB
cat config/gnbcfg.yaml > config/gnbcfg$i.yaml

# Change the network IP in the gNB file based on the gNB number
sed -i "s#$link_gnb#gnb$i.free5gc.org#g" config/gnbcfg$i.yaml

done

# Add network configurations at the end of the file
echo "$final" >> "$nome_arquivo"

# Build the ueransim containers
for ((j=0; j<$number_gnb; j++));
do
docker compose -f docker-compose-setup.yaml build ueransim$j
docker compose -f docker-compose-setup.yaml build ueransim-gnb$j
done

sleep 5

# Start the services
docker compose -f docker-compose-setup.yaml up


# At the end of the script execution, delete the generated configuration files.
for ((k=0; k< $number_gnb; k++));
do

file_name="config/uecfg$k.yaml"
rm -rf "${file_name}"

file_name="config/gnbcfg$k.yaml"
rm -rf "${file_name}"   
done

file_name="docker-compose-setup.yaml"
rm -rf "${file_name}"

