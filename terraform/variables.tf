variable "database_name" {}
variable "database_password" {}
variable "database_user" {}

variable "region" {}
variable "vpc_cidr" {}
variable "subnet1_cidr" {}
variable "subnet2_cidr" {}
variable "subnet3_cidr" {}

variable "availability_zone1" {}
variable "availability_zone2" {}

variable "ec2_instance_type" {}
variable "ec2_image_id" {}
variable "db_instance_class" {}
//variable "PUBLIC_KEY_PATH" {}
//variable "PRIV_KEY_PATH" {}
variable "root_volume_size" {}