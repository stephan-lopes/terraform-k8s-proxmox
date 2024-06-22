variable "ssh_private_key" {
  type = string
}

variable "ssh_public_key" {
  type = string
}


variable "initial_vm_id" {
  type = number
}

variable "vm_type" {
  type = string
}

variable "vm_config_stats" {
  type = object({
    memory = number
    cpus   = number
  })
  description = "number of cpus cores and memory"
  default = {
    memory = 2048
    cpus   = 2
  }
}

variable "vm_count" {
  type = number
}
