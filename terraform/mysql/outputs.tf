output "endpoint" { 
  value = "${aws_db_instance.mysql.endpoint}"
}

output "connection_string" { 
  value = "mysql://${var.db_user}:${var.db_password}@${aws_db_instance.mysql.endpoint}/${var.db_name}"
}