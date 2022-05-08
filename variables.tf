# You can find variables in this file. You can change/delete/add more variables for your own convenience.

variable "region" {
    default     = "eu-central-1"
    type        = string
    description = "Please enter region you need" 
}

variable "instance_type" {
    default     = "t3.micro"
    type        = string
    description = "Please choose instance type you need"
}

variable "min_size" {
    type = string
    description = "Please choose minimum number of instances for Auto Scaling Group"
}

variable "max_size" {
    type = string
    description = "Please choose maximum number of instances for Auto Scaling Group"
}

variable "desired_size" {
    type = string
    description = "Please choose desired number of instances for Auto Scaling Group"
}

variable "health_check_grace_period" {
    type = string
    default = 300
}

variable "asg_health_check_type" {
    type = string
    default = "ELB"
}

variable "alb_listener_action" {
    type = string
    default = "forward"
}