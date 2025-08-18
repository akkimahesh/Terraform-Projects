# Terraform-Project
git clone https://github.com/akkimahesh/Terraform-Projects.git
After completed the gitclone
In your system you can denfine you own variable block.
After difining 
write the module block like below
    module "module-multi-Tier" {
      source = ".//module-multi-Tier"
      # Other arguments corresponding to input variables defined by the module
      # ...
    }
