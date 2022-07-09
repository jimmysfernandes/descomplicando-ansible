# Descomplicando o Ansible

Este respositório foi criado com o intúito de documentar os exercícios realizados durante o curso [Descomplicando o Ansible](https://www.linuxtips.io/products/treinamento-descomplicando-o-ansible?_pos=1&_psq=ansi&_ss=e&_v=1.0) da [LinuxTips](https://www.linuxtips.io/)


Para realizar os exercícios em um ambiente mais próximo de um cenário real foram utilizados os recursos disponiblizados pela [OCI](https://cloud.oracle.com/) no plano [always-free](https://www.oracle.com/br/cloud/free/#always-free), abaixo seguem os passos que devem ser realizados para permitir a execução dos exemplos presentes nesse respositório.

## OCI cli

Primeiramente é necessário criar uma conta na OCI e após configura a sua ferramenta de linha de comando.

- Criacão da conta -> https://signup.cloud.oracle.com/?sourceType=_ref_coc-asset-opcSignIn&language=en_US
- Instalação e configuração do CLI -> https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm

Caso já tenha uma conta e o CLI já estaja configurado basta realizar o login com o comando abaixo.

```sh
$ oci session authenticate --region sa-saopaulo-1 --profile-name descomplicando-ansible
```

O refresh da sessão pode ser feito com o comando: 

```sh
$ oci session refresh --profile descomplicando-ansible
```

## Terraform

O terraform foi utilizado para prover as infra necessária, para criação das instâncias na OCI é necessário criar uma arquivo com as variaveis necessárias, este arquivo deve ser salvo na pasta ./terraform e deve ter a extensão .tfvars

```tf
compartment_id      = "<Este informação é recuperada na OCI>"
region              = "sa-saopaulo-1"
availability_domain = "adUa:SA-SAOPAULO-1-AD-1"
vm_shape            = "VM.Standard.A1.Flex"
vm_memory_in_gbs    = 6
vm_ocpus            = 1
vm_image_id         = "ocid1.image.oc1.sa-saopaulo-1.aaaaaaaafl5tljzvlebqvrgs4nog6mg7n6indhgd6lzdxmtunsey735htmfa"
```
> Importante: As informações de **region** e **availability_domain** podem variar se no momento da criação da conta outro regição for selecionada. As informações de **vm_shape** e **vm_image_id** podem sofrer alteração, importante consultar as regras do [always-free](https://www.oracle.com/br/cloud/free/#always-free)

Após criar o arquivo basta executar o comando abaixo:

```sh
$ terraform -chdir=./terraform apply

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

ssh-with-ubuntu-user = <<EOT
ssh -l ubuntu -p 22 -i id_rsa 132.226.250.243 # eliot-01 backend
ssh -l ubuntu -p 22 -i id_rsa 144.22.240.2 # eliot-02 frontend
ssh -l ubuntu -p 22 -i id_rsa 168.138.227.188 # eliot-03 backend
ssh -l ubuntu -p 22 -i id_rsa 144.22.242.201 # eliot-04 frontend
EOT
```

Caso queira consultar as informações das instâncias novamente basta executar o comando abaixo.

```sh
$ terraform -chdir=./terraform output
ssh-with-ubuntu-user = <<EOT
ssh -l ubuntu -p 22 -i id_rsa 132.226.250.243 # eliot-01 backend
ssh -l ubuntu -p 22 -i id_rsa 144.22.240.2 # eliot-02 frontend
ssh -l ubuntu -p 22 -i id_rsa 168.138.227.188 # eliot-03 backend
ssh -l ubuntu -p 22 -i id_rsa 144.22.242.201 # eliot-04 frontend
EOT
```

Para encerrar o ambiente basta executar o comando abaixo.

```sh
$ terraform -chdir=./terraform destroy
```

## Ansible

Após o provisionamento do ambiente é possivél ver que foram criadas 4 maquinas, duas como "frontend" e duas como "backend", com essa informação em mãos devemos criar o arquivo de inventário que será executado nos testes com o Ansible.

```txt
[backend]
144.22.240.2     eliot-02
144.22.242.201   eliot-04

[frontend]
132.226.250.243  eliot-01
168.138.227.188  eliot-03
```

> O arquivo deve ser criado na raiz do projeto

### Ad-hoc

Na pasta ansible/ad-hoc estão os exemplos de comandos simples executados diretamente no console.

### Playbook

Na pasta ansible/playbook estão os exemplos de comandos mais complexos executados de maneira orquestrada.