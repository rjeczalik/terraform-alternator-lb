provider aws {
	access_key = var.aws_access_key
	secret_key = var.aws_secret_key
	region     = var.aws_region
}

locals {
	name_prefix = format("Scylla-Cloud-Cluster-%d", var.cluster_id)
	domain      = format("scylla-cloud-alb-cluster-%d.%s", var.cluster_id, var.basedomain)
	certificate = var.aws_certificate[var.aws_region]
	tags        = merge(var.aws_tags,
		map("Service", "ALB"),
		map("ClusterID", var.cluster_id),
		map("Environment", var.environment),
	)
}

resource "aws_lb" "scylla_cloud" {
	name               = format("%s-ALB", local.name_prefix)
	internal           = var.internal
	subnets            = var.aws_subnets
	security_groups    = [aws_security_group.allow_http.id]
	idle_timeout       = 400
	tags               = local.tags
	load_balancer_type = "application"
	enable_http2       = true

	enable_deletion_protection = false
}

resource "aws_lb_listener" "scylla_cloud_https" {
	load_balancer_arn = aws_lb.scylla_cloud.arn
	port              = "443"
	protocol          = "HTTPS"
	ssl_policy        = "ELBSecurityPolicy-2016-08"
	certificate_arn   = local.certificate

	default_action {
		type             = "forward"
		target_group_arn = aws_lb_target_group.scylla_cloud.arn
	}

	count = var.internal ? 0 : 1
}

resource "aws_lb_listener" "scylla_cloud_http" {
	load_balancer_arn = aws_lb.scylla_cloud.arn
	port              = "80"
	protocol          = "HTTP"

	default_action {
		type             = "forward"
		target_group_arn = aws_lb_target_group.scylla_cloud.arn
	}

	count = var.internal ? 1 : 0
}

resource "aws_lb_listener" "scylla_cloud_redir" {
	load_balancer_arn = aws_lb.scylla_cloud.arn
	port              = "80"
	protocol          = "HTTP"

	default_action {
		type = "redirect"

		redirect {
			port        = "443"
			protocol    = "HTTPS"
			status_code = "HTTP_301"
		}
	}

	count = var.internal ? 0 : 1
}

resource "aws_lb_target_group" "scylla_cloud" {
	name     = format("%s-Group", local.name_prefix)
	port     = var.port
	protocol = "HTTP"
	vpc_id   = var.aws_vpc
	tags     = local.tags

	health_check {
		timeout  = 5
		interval = 30
		port     = var.port
		path     = "/"

		healthy_threshold   = 2
		unhealthy_threshold = 2
	}

	stickiness {
		type    = "lb_cookie"
		enabled = true
	}
}

resource "aws_lb_target_group_attachment" "scylla_cloud" {
	target_group_arn = aws_lb_target_group.scylla_cloud.arn
	target_id        = element(var.aws_instances.*, count.index)
	port             = var.port

	count = length(var.aws_instances)
}

resource "aws_security_group" "allow_http" {
	name        = format("%s-SGLoadBalancer", local.name_prefix)
	description = "Allow HTTP/HTTPS inbound traffic"
	vpc_id      = var.aws_vpc
	tags        = local.tags

	ingress {
		from_port   = 443
		to_port     = 443
		protocol    = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	ingress {
		from_port   = 80
		to_port     = 80
		protocol    = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	egress {
		from_port   = 0
		to_port     = 0
		protocol    = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}
}

resource "aws_route53_record" "scylla_cloud" {
	zone_id = var.aws_route53_zone
	name    = local.domain
	type    = "A"

	alias {
		name                   = aws_lb.scylla_cloud.dns_name
		zone_id                = aws_lb.scylla_cloud.zone_id
		evaluate_target_health = true
	}

	count = var.internal ? 0 : 1
}
