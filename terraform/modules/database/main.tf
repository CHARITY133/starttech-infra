############################################
# Database Module: ElastiCache Redis
############################################

resource "aws_elasticache_subnet_group" "starttech_redis" {
  name       = "starttech-redis-subnet-group"
  subnet_ids = var.private_subnet_ids
}

resource "aws_security_group" "starttech_redis" {
  name        = "starttech-redis-sg"
  description = "Allow Redis traffic only from EKS worker nodes"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Redis from EKS nodes"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [var.eks_cluster_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "starttech-redis-sg"
  }
}

resource "aws_elasticache_cluster" "starttech_redis" {
  cluster_id           = "starttech-redis"
  engine               = "redis"
  engine_version        = "7.1"
  node_type             = "cache.t3.micro"
  num_cache_nodes       = 1
  parameter_group_name = "default.redis7"
  port                  = 6379

  subnet_group_name  = aws_elasticache_subnet_group.starttech_redis.name
  security_group_ids = [aws_security_group.starttech_redis.id]

  tags = {
    Name = "starttech-redis"
  }
}
