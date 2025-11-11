resource "aws_db_instance" "postgres" {
  identifier          = var.project_name
  allocated_storage   = 10
  engine              = "postgres"
  engine_version      = "16.3"
  instance_class      = "db.t3.micro"
  db_name             = "serverpod"
  username            = "postgres"
  password            = var.DATABASE_PASSWORD_PRODUCTION
  skip_final_snapshot = true
  vpc_security_group_ids = [
    aws_security_group.database.id
  ]
  publicly_accessible  = true
  db_subnet_group_name = module.vpc.database_subnet_group_name
  
  # Backup Configuration (AC2, AC3)
  backup_retention_period = 30  # 30-day retention per AC3
  backup_window          = "03:00-04:00"  # UTC backup window (minimize impact)
  maintenance_window     = "sun:04:00-sun:05:00"  # UTC maintenance window
  
  # Enable Point-in-Time Recovery (AC2)
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  
  # Storage encryption
  storage_encrypted = true
  
  # Enable deletion protection for production
  deletion_protection = false  # Set to true in production
  
  tags = {
    Name        = "${var.project_name}-database"
    Environment = "production"
    BackupEnabled = "true"
    ManagedBy   = "terraform"
  }
}

resource "aws_route53_record" "database" {
  zone_id = var.hosted_zone_id
  name    = "${var.subdomain_database}.${var.top_domain}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${aws_db_instance.postgres.address}"]
}

# Makes the database accessible from anywhere.
resource "aws_security_group" "database" {
  name = "${var.project_name}-database"
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Staging
resource "aws_db_instance" "postgres_staging" {
  count = var.enable_staging_server ? 1 : 0

  identifier          = "${var.project_name}-staging"
  allocated_storage   = 10
  engine              = "postgres"
  engine_version      = "16.3"
  instance_class      = "db.t3.micro"
  db_name             = "serverpod"
  username            = "postgres"
  password            = var.DATABASE_PASSWORD_STAGING
  skip_final_snapshot = true
  vpc_security_group_ids = [
    aws_security_group.database.id
  ]
  publicly_accessible  = true
  db_subnet_group_name = module.vpc.database_subnet_group_name
  
  # Backup Configuration (reduced retention for staging)
  backup_retention_period = 7  # 7-day retention for staging
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  # Enable CloudWatch logs
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  
  # Storage encryption
  storage_encrypted = true
  
  tags = {
    Name        = "${var.project_name}-staging-database"
    Environment = "staging"
    BackupEnabled = "true"
    ManagedBy   = "terraform"
  }
}

resource "aws_route53_record" "database_staging" {
  count = var.enable_staging_server ? 1 : 0

  zone_id = var.hosted_zone_id
  name    = "${var.subdomain_database_staging}.${var.top_domain}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${aws_db_instance.postgres_staging[0].address}"]
}