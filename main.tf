terraform {
  backend "remote" {
    hostname     = "terraform.orginization.com"
    organization = "orrg namename"
    workspaces {
       name = "DCL-OT-SD-GNR-DEV"
    }
  }
}

 

provider "aws" {
  region = "us-east-1"
}

 

provider "aws" {
  region = "us-east-2"
  alias = "use2"
}

 


###########################################################
## S3
resource "aws_s3_bucket" "a" {
   bucket = "bk-aws-limit-monitor"
   acl    = "private"

 

 

 

   tags = {
     Name        = "bk-aws-limit-monitor"
     Environment = "Dev"
   }
 }
