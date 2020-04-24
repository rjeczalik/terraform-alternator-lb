locals {
	cluster   = yamldecode(file("cluster.yaml"))

	region     = local.cluster.regions[0].externalid
	vpc        = local.cluster.vpcs[0].externalid
	cluster_id = local.cluster.cluster.cluster.id
	subnets    = tolist(local.cluster.subnets[*].externalid)
	instances  = tolist(local.cluster.nodes[*].externalid)
}

module "alternator" {
	source = "./modules/nlb"   # Network Load Balancer
	# source = "./modules/alb" # Application Load Balancer

	aws_region       = local.region
	aws_vpc          = local.vpc
	aws_subnets      = slice(local.subnets, 1, length(local.subnets))
	aws_instances    = local.instances
	aws_certificate  = {
		"us-east-1": "arn:aws:acm:us-east-1:734708892259:certificate/5f83d6f8-1035-45dd-9e2f-eb8aa59f92ca"
	}
	aws_route53_zone = "Z05410223JZ19MWMQVU01"
	cluster_id       = local.cluster_id
	basedomain       = "lab.dbaas.scyop.net"
	environment      = "lab"
}
