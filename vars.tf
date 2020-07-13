# Resource Group
variable "resourcegroup_name" {
    description = "Recently created resource group"
    default     = "UdacityWebApp"
}

# Resource Location
variable "location" {
    description = "Physical location of the resources"
    default     = "East US"    
}

# Tags
variable "tags" {
    type        = map(string)
    default     = {
        project  = "UdacityWebApp"
    }
}

# VM count
variable "vm_count" {
    description = "How many VMs we are going to deploy"
    default     = "2"
}

# Prefix
variable  "prefix" {
    default    = "UdacityWeApp"
}