output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "classic_lb_dns" {
  description = "DNS name of the Classic Load Balancer"
  value       = aws_elb.web.dns_name
}

output "load_balancer_url" {
  description = "Full URL to access your web application"
  value       = "http://${aws_elb.web.dns_name}"
}

output "bastion_public_ip" {
  description = "Public IP address of the bastion host"
  value       = aws_eip.bastion.public_ip
}

output "bastion_ssh_command" {
  description = "Command to SSH into bastion host"
  value       = "ssh admin@${aws_eip.bastion.public_ip}"
}

output "web_server_1_private_ip" {
  description = "Private IP of Web Server 1"
  value       = aws_instance.web_1.private_ip
}

output "web_server_2_private_ip" {
  description = "Private IP of Web Server 2"
  value       = aws_instance.web_2.private_ip
}

output "database_private_ip" {
  description = "Private IP of Database Server"
  value       = aws_instance.database.private_ip
}

output "ssh_to_web_1_command" {
  description = "Command to SSH to Web Server 1 FROM bastion"
  value       = "ssh webadmin@${aws_instance.web_1.private_ip}"
}

output "ssh_to_web_2_command" {
  description = "Command to SSH to Web Server 2 FROM bastion"
  value       = "ssh webadmin@${aws_instance.web_2.private_ip}"
}

output "ssh_to_database_command" {
  description = "Command to SSH to Database Server FROM bastion"
  value       = "ssh dbadmin@${aws_instance.database.private_ip}"
}

output "connection_info" {
  description = "Summary of all connection information"
  value = <<-EOT

  ================================
  DEPLOYMENT COMPLETE!
  ================================

  WEBSITE: http://${aws_elb.web.dns_name}

  BASTION: ssh admin@${aws_eip.bastion.public_ip}
     Password: BastionPass123!

  WEB SERVERS (from bastion):
     Web 1: ssh webadmin@${aws_instance.web_1.private_ip}
     Web 2: ssh webadmin@${aws_instance.web_2.private_ip}
     Password: WebPassword123!

  DATABASE (from bastion):
     SSH: ssh dbadmin@${aws_instance.database.private_ip}
     Password: DbPassword123!
     PostgreSQL: sudo -u postgres psql

  ================================

  EOT
}
