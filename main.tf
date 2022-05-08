# ---------------------------------------------
/* Provision plan for Green/Blue deployment Highly available infrastructure with Zero Downtime

What we need to reach our goal:

1. Latest AMI for Amazon Linux 
2. Create security group (in sec-group.tf file) and default subnets in 2 Availability Zones
3. Creating Launch Configuration
4. Creating Auto Scaling Group which covers 2 Availability Zones (Can be increased depending on region)
5. Creating Application Load Balancer
6. Making sure Infrastructure has Zero Downtime with the help of "create_before_destroy = true" line

*/

# As we are creating resources in AWS Cloud, provider will be chosen as "aws" and additionally we include argument - region, in order to clarify in which region we will create our resources
provider "aws" {
    region = var.region
}

# We are choosing all availability zones in current region
data "aws_availability_zones" "current" {}

# Below data source will help us always get latest version of Amazon Linux AMI
data "aws_ami" "amazon_linux" {
    most_recent = true 
    owners = ["137112412989"]   # This is taken from AMI section of Amazon Management Console.
    filter {
        name = "name"
        values = ["amzn2-ami-kernel-5.10-hvm-*-gp2"]
    }
}

//----------------------------------------------------------------

# We are creating default public subnet in each availability zone
resource "aws_default_subnet" "default_sub_az1" {
  availability_zone = data.aws_availability_zones.current.names[0]
  tags = {
    Name = "Default subnet 1"
  }
}

resource "aws_default_subnet" "default_sub_az2" {
  availability_zone = data.aws_availability_zones.current.names[1]
  tags = {
    Name = "Default subnet 2"
  }
}

//------------------------------------------------------------------

/* Launch configuration is needed for Auto Scaling Group to understand what kind of EC2 instance it needs to create. Instead of "name", please use "name_prefix", because if you are creating
 more than one resource, you may face error as Terraform won't be able to create two resources with same name. With name_prefix argument, Amazon will add random ending after "...lc-". */
resource "aws_launch_configuration" "green_blue_lc" {
  name_prefix   = "green_blue_lc-"                            
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  security_groups = [aws_security_group.green-blue-sg.id]     # We have defined security group in "sec-group.tf" file in this repo.
  user_data = file("user_data_apache.sh")                     # user_data_apache.sh is separate file in this repo. You can add your own script and adjust the view of your home page

  lifecycle {
    create_before_destroy = true                              # Zero down-time option will help new resource to be created before old one is destroyed.
  }
}

//--------------------------------------------------------------------

resource "aws_autoscaling_group" "green_blue_asg" {
  name                      = "ASG_${aws_launch_configuration.green_blue_lc.name}"    # We are using name this way in order to see which launch configuration our Auto scaling group uses
  min_size                  = var.min_size                                            # You will need to type the amount when you run /terraform apply/ command
  max_size                  = var.max_size                                            # You will need to type the amount when you run /terraform apply/ command
  desired_capacity          = var.desired_size                                        # You will need to type the amount when you run /terraform apply/ command
  health_check_grace_period = var.health_check_grace_period
  health_check_type         = var.asg_health_check_type
  launch_configuration      = aws_launch_configuration.green_blue_lc.name
  vpc_zone_identifier       = [aws_default_subnet.default_sub_az1.id, aws_default_subnet.default_sub_az2.id]

//---------------------------------------------------------------------

  # Tags are very helpful and important to have proper tags in your cloud view. This tag part is taken from Denis Astahov. You may find his courses in udemy.com
  dynamic "tag" {
    for_each = {
      Name   = "WebServer in ASG"
      Owner  = "Ali Valizada"
      TAGKEY = "TAGVALUE"
    }
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

//--------------------------------------------------------------------

# Target group is for Application Load Balancer (ALB). Instances will get registered under this resource and ALB will be able to send requests to these instances.
resource "aws_lb_target_group" "green-blue-tg-group" {
  name        = "green-blue-target-blue"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_default_vpc.default.id
}

//--------------------------------------------------------------------

/* In this repo, we are not created a separate VPC, we are just defining the default one. As a rule, before creating the resource, Terraform is checking whether an identical resource exists. 
If yes, Terraform ignores it. In our case now, we need to define "vpc_id" argument for Target Group above, so in order to give it proper value, we are defining our default VPC as below.*/
resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

//--------------------------------------------------------------------

/* This resource is very important to connect instances to Target groups. Application Load Balancer (ALB) is sending requests to instances which are mentioned in Target Groups. 
NOTE: Without "aws_autoscaling_attachment", your resources will be created still, but as created instances won't get registered under target group, ALB won't find any instances */
resource "aws_autoscaling_attachment" "asg_attachment_bar" {
  autoscaling_group_name = aws_autoscaling_group.green_blue_asg.id
  lb_target_group_arn    = aws_lb_target_group.green-blue-tg-group.arn
}

# Creating Application Load Balancer
resource "aws_lb" "green-blue-alb" {
  name               = "green-blue-alb"
  internal           = false           # If true, the LB will be internal without access to internet
  load_balancer_type = "application"
  security_groups    = [aws_security_group.green-blue-sg.id]
  subnets            = [aws_default_subnet.default_sub_az1.id, aws_default_subnet.default_sub_az2.id]

  enable_deletion_protection = false # If true, deletion of the load balancer will be disabled via the AWS API. This will prevent Terraform from deleting the load balancer.

  # access_logs are stored in the root by default

  tags = {
    Environment = "production"
  }
}

# Listener helps Load Balancer to know which action to take (forward, redirect etc.), which port/protocol and which target group to use
resource "aws_lb_listener" "green-blue-alb-listener" {
  load_balancer_arn = aws_lb.green-blue-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = var.alb_listener_action
    target_group_arn = aws_lb_target_group.green-blue-tg-group.arn
  }
}