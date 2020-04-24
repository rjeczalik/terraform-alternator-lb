variable aws_access_key {
	type        = string
	description = "AWS Access Key ID"
	default     = ""
}

variable aws_secret_key {
	type        = string
	description = "AWS Secret Access Key"
	default     = ""
}

variable aws_region {
	type        = string
	description = "AWS Region"
	default     = "us-east-1"
}

variable aws_tags {
	type        = map(string)
	description = "Tags for each created AWS resource"
	default     = {}
}

variable aws_vpc {
	type        = string
	description = "VPC ID to place the instances in"
}

variable aws_subnets {
	type        = list(string)
	description = "List of subnets to place the instances in"
}

variable aws_instances {
	type        = list(string)
	description = "Instance IDs to attach to the TargetGroup"
}

variable aws_certificate {
	type        = map(string)
	description = "Certificate ARN to use for the LoadBalancer Listener per region"
}

variable aws_route53_zone {
	type        = string
	description = "Route53 ID of zone to use"
}

variable environment {
	type        = string
	description = "Scylla Cloud Environment"
}

variable cluster_id {
	type        = number
	description = "ID of Scylla Cloud cluster"
}

variable basedomain {
	type        = string
	description = "Basedomain for Scylla Cloud cluster"
}

variable port {
	type        = number
	description = "Basedomain for Scylla Cloud cluster"
	default     = 8000
}
