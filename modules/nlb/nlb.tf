provider aws {
	access_key = var.aws_access_key
	secret_key = var.aws_secret_key
	region     = var.aws_region
}

locals {
	name_prefix = format("Scylla-Cloud-Cluster-%d", var.cluster_id)
	domain      = format("scylla-cloud-nlb-cluster-%d.%s", var.cluster_id, var.basedomain)
	certificate = var.aws_certificate[var.aws_region]
	tags        = merge(var.aws_tags,
		map("Service", "NLB"),
		map("ClusterID", var.cluster_id),
		map("Environment", var.environment),
	)
}

resource "aws_lb" "scylla_cloud" {
	name               = format("%s-NLB", local.name_prefix)
	internal           = false
	subnets            = var.aws_subnets
	tags               = local.tags
	load_balancer_type = "network"

	enable_deletion_protection       = false
	enable_cross_zone_load_balancing = false
}

resource "aws_lb_listener" "scylla_cloud" {
	load_balancer_arn = aws_lb.scylla_cloud.arn
	port              = "443"
	protocol          = "TLS"
	ssl_policy        = "ELBSecurityPolicy-2016-08"
	certificate_arn   = local.certificate

	default_action {
		type             = "forward"
		target_group_arn = aws_lb_target_group.scylla_cloud.arn
	}
}

resource "aws_lb_target_group" "scylla_cloud" {
	name     = format("%s-Group", local.name_prefix)
	port     = var.port
	protocol = "TCP"
	vpc_id   = var.aws_vpc

	health_check {
		interval = 30
		port     = var.port
		path     = "/"

		healthy_threshold   = 2
		unhealthy_threshold = 2
	}
}

resource "aws_lb_target_group_attachment" "scylla_cloud" {
	target_group_arn = aws_lb_target_group.scylla_cloud.arn
	target_id        = element(var.aws_instances.*, count.index)
	port             = var.port

	count = length(var.aws_instances)
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
}
