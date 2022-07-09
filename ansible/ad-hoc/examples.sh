## Modules REF -> https://docs.ansible.com/ansible/2.9/modules/modules_by_category.html

## Ping in all hosts
ansible -u ubuntu -i ./hosts all --private-key terraform/id_rsa -m ping

## Ping in unique host
ansible -u ubuntu -i ./hosts frontend --private-key terraform/id_rsa -m ping

## Install app
ansible -u ubuntu -i ./hosts all --private-key terraform/id_rsa -m apt -a "update_cache=yes name=cmatrix state=present" -b

## Shell commands
ansible -u ubuntu -i ./hosts all --private-key terraform/id_rsa -m shell -a "uptime"

ansible -u ubuntu -i ./hosts all --private-key terraform/id_rsa -m shell -a "ls /tmp"

## Setup
ansible -u ubuntu -i ./hosts all --private-key terraform/id_rsa -m setup

ansible -u ubuntu -i ./hosts frontend --private-key terraform/id_rsa -m setup -a "filter=ansible_distribuition"
