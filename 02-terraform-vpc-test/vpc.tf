module "vpc" {
    #source = "../01-terraform-aws-vpc"
     source = "git::https://github.com/Medasanicharan/01-terraform-aws-vpc.git?ref=main"
}