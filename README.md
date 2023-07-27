<p align="center">
  <a href="https://github.com/lasseufpa/RANGEN">
    <img src="https://i.ibb.co/s6dpxr5/imagem.png" width="150" alt="RANGEN">
  </a>
</p>

<p align="center">RANGEN is a shell script-based tool that automates the process of creating UE (User Equipment) and gNodeB containers in UERANSIM. By specifying the desired number of UEs connected to each gNodeB container and the total number of gNodeB containers, the script automates the generation of these containers. This eliminates the manual creation and configuration, making it easier to deploy and manage a large number of UEs and gNBs without the need for writing additional code.</p>

## Current Status

The functionality of generating gNBs with a defined number of UEs has already been tested and is ready to be used with the Free5GC core. However, in the future, I should add other cores such as Open5GS. The project can be utilized for testing the 5G Core Network and studying the 5G System in conjunction with UERANSIM.


## Features

- Automated generation of UE and gNodeB containers.
- Eliminates the need for manual configuration.
- Supports scalable deployment of a large number of UEs and gNBs.
- Replaces critical values in the configuration files of UEs and gNBs to ensure correct connections between the RAN components and the 5G network core.

## Requirements

- [free5gc-compose](https://github.com/free5gc/free5gc-compose)
- Shell

## Installation

Adicione o rangen.sh e os 3 docker-compose files dentro da pasta do free5gc-compose :

```
# O RANGEN.
wget "https://github.com/lasseufpa/RANGEN/blob/main/rangen.sh"

# Um arquivo que usamos como base para a geração do docker-compose final.
wget "https://github.com/lasseufpa/RANGEN/blob/main/docker-compose-base"

```

Adicione o arquivo start.sh na pasta ueransim do free5gc-compose
```
cd ./ueransim
wget "https://github.com/lasseufpa/RANGEN/blob/main/start.sh"
cd ..
```

## Usage
To use RANGEN, you need to specify the desired number of UEs connected to each gNodeB container and the total number of gNodeB containers. The script will then automate the generation of these containers.


```
sudo ./rangen.sh <number_of_Ues> <number_of_gNodeBs>
```

## Contributing

Any contributions you make are greatly appreciated via Pull Request.

## License

This project is licensed under the GNU General Public License v3.0. You can find the full text of the license [here](https://www.gnu.org/licenses/gpl-3.0.en.html).

## Acknowledgements


This tool was developed as part of a research project at LASSE - Telecommunications, Automation and Electronics Research and Development Center, Belém-PA, Brazil. The project was supported by the Innovation Center, Ericsson Telecomunicações S.A. and RNP, Brazil.


