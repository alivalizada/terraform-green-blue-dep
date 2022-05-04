# We can add all outputs to this file. Outputs are really useful to see details of created resources.

output "aws_ami_id" {
    value = data.aws_ami.amazon_linux.id
}

output "aws_availability_zone_1" {
    value = data.aws_availability_zones.current.names[0]
}

output "aws_availability_zone_2" {
    value = data.aws_availability_zones.current.names[1]
}

output "green-blue-alb_url" {
  value = aws_lb.green-blue-alb.dns_name
}

output "default-vpc-id" {
    value = aws_default_vpc.default.id
}

output "target_group_arn" {
    value = aws_lb_target_group.green-blue-tg-group.arn
}