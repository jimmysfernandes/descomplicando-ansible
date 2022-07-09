### Provider

terraform {
  required_providers {
    oci = {
      source = "hashicorp/oci"
      # version = "4.62.0"
    }
  }
}

provider "oci" {
  region              = var.region
  auth                = "SecurityToken"
  config_file_profile = "learn-terraform"
}

### Variables (should definied at terraform.tfvars)

variable "compartment_id" {
  description = "OCID from your tenancy page"
  type        = string
}

variable "region" {
  description = "region where you have OCI tenancy"
  type        = string
}

variable "availability_domain" {
  description = "availability domain"
  type        = string
}

variable "vm_shape" {
  description = "type of machine instancies"
  type        = string
}

variable "vm_memory_in_gbs" {
  description = "amount of memory in gbs"
  type        = number
}

variable "vm_ocpus" {
  description = "amount of cpu"
  type        = number
}

variable "vm_image_id" {
  description = "id of image uses to create VM"
  type        = string
}

### Network

resource "oci_core_vcn" "external" {
  dns_label      = "external"
  cidr_block     = "172.16.0.0/20"
  compartment_id = var.compartment_id
  display_name   = "External VCN"
}

resource "oci_core_internet_gateway" "internet_gateway" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.external.id
}

resource "oci_core_default_route_table" "route_table" {
  manage_default_resource_id = oci_core_vcn.external.default_route_table_id
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.internet_gateway.id
  }
}

resource "oci_core_default_security_list" "security_list" {
  manage_default_resource_id = oci_core_vcn.external.default_security_list_id
  ingress_security_rules {
    protocol = "all"
    source   = "0.0.0.0/0"
  }
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
}

resource "oci_core_subnet" "external_dev" {
  vcn_id                     = oci_core_vcn.external.id
  route_table_id             = oci_core_default_route_table.route_table.id
  security_list_ids          = [ oci_core_default_security_list.security_list.id ]
  cidr_block                 = "172.16.0.0/24"
  compartment_id             = var.compartment_id
  display_name               = "Dev subnet"
  prohibit_public_ip_on_vnic = false
  dns_label                  = "dev"
}

### Security

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "local_file" "ssh_private_key" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "id_rsa"
  file_permission = "0600"
}

resource "local_file" "ssh_public_key" {
  content         = tls_private_key.ssh.public_key_openssh
  filename        = "id_rsa.pub"
  file_permission = "0600"
}

locals {
  authorized_keys = [chomp(tls_private_key.ssh.public_key_openssh)]
}

### VMS 

locals {
  instancies = {
    for i in range(1, 5) :
    i => {
      vm_name    = format("eliot-%02d", i)
      ip_address = format("172.16.0.%d", 10 + i)
      role       = (i % 2) == 0 ? "frontend" : "backend"
    }
  }
}

resource "oci_core_instance" "_" {
  for_each            = local.instancies
  display_name        = each.value.vm_name
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_id
  shape               = var.vm_shape
  shape_config {
    memory_in_gbs = var.vm_memory_in_gbs
    ocpus         = var.vm_ocpus
  }
  source_details {
    source_id   = var.vm_image_id
    source_type = "image"
  }
  create_vnic_details {
    subnet_id  = oci_core_subnet.external_dev.id
    private_ip = each.value.ip_address
  }
  metadata = {
    ssh_authorized_keys = join("\n", local.authorized_keys)
    role = each.value.role
  }
}

### outputs

output "ssh-with-ubuntu-user" {
  value = join(
    "\n",
    [for i in oci_core_instance._ :
      format(
        "ssh -l ubuntu -p 22 -i %s %s # %s %s",
        local_file.ssh_private_key.filename,
        i.public_ip,
        i.display_name,
        i.metadata.role
      )
    ]
  )
}
