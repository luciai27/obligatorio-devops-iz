data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

terraform {
  backend "s3" {}
}

data "aws_vpc" "shared" {
  filter {
    name   = "tag:Name"
    values = ["voting_app-vpc"]
  }
}

data "aws_internet_gateway" "shared" {
  filter {
    name   = "tag:Name"
    values = ["voting_app-igw"]
  }
}

resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = data.aws_vpc.shared.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${data.aws_vpc.shared.tags.Name}-public-${var.environment}-${count.index + 1}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = data.aws_vpc.shared.id

  tags = {
    Name = "${data.aws_vpc.shared.tags.Name}-public-${var.environment}-rt"
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = data.aws_internet_gateway.shared.id
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}



resource "aws_eks_cluster" "eks" {
  name     = var.cluster_name
  role_arn = data.aws_iam_role.lab_role.arn

  enabled_cluster_log_types = [ "api", "audit", "authenticator" ]

  vpc_config {
    subnet_ids = aws_subnet.public[*].id
  }

  logging {
    cluster_logging {
      enabled = true
      types   = ["api", "audit", "authenticator"]
    }
  }

  tags = {
    Name = var.cluster_name
  }

  depends_on = [aws_cloudwatch_log_group.eks_cluster_log_group]
}

resource "aws_eks_node_group" "node_group" {
  cluster_name    = var.cluster_name
  node_group_name = var.node_group_name
  node_role_arn   = data.aws_iam_role.lab_role.arn
  subnet_ids      = aws_subnet.public[*].id

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t3.small"]
  ami_type       = "AL2023_x86_64_STANDARD"

  tags = {
    Name = var.node_group_name
  }

  depends_on = [aws_eks_cluster.eks]
}

data "aws_instances" "eks_nodes" {
  filter {
    name   = "subnet-id"
    values = aws_subnet.public[*].id
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }

  depends_on = [aws_eks_node_group.node_group]
}

resource "aws_cloudwatch_dashboard" "vote" {
  dashboard_name = "dashboard-vote"

  dashboard_body = jsonencode({
    widgets = flatten([
      for instance_id in data.aws_instances.eks_nodes.ids : [
        {
          type   = "metric"
          x      = 0
          y      = 0
          width  = 12
          height = 6

          properties = {
            metrics = [
              [
                "AWS/EC2",
                "CPUUtilization",
                "InstanceId",
                instance_id
              ]
            ]
            period = 300
            stat   = "Average"
            region = "us-east-1"
            title  = "EC2 CPU Utilization - ${instance_id}"
          }
        }
      ]
    ])
  })
}

resource "aws_cloudwatch_metric_alarm" "cpu_utilization_alarm" {
  alarm_name          = "cpu-utilization-eks-cluster"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CpuUtilized"
  namespace           = "ContainerInsights"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"
  treat_missing_data = "notBreaching"
 
  dimensions = {
    ClusterName = var.cluster_name
  }
 
  alarm_description  = "Alarma cuando la utilización de CPU excede el 80%"
  alarm_actions      = [aws_sns_topic_subscription.email_subscription.arn]
}
 
resource "aws_cloudwatch_metric_alarm" "memory_utilized_alarm" {
  alarm_name          = "memory-utilized-eks-cluster"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilized"
  namespace           = "ContainerInsights"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"
  treat_missing_data = "notBreaching"
 
  dimensions = {
    ClusterName = var.cluster_name
  }
 
  alarm_description  = "Alarma cuando la utilización de memoria excede el 80%"
  alarm_actions      = [aws_sns_topic_subscription.email_subscription.arn]
}

resource "aws_sns_topic" "alarm_topic" {
  name = "eks-alarms"
}
 
resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.alarm_topic.arn
  protocol  = "email"
  endpoint  = "luciaibarburu@hotmail.com"
}

resource "aws_cloudwatch_log_group" "eks_cluster_log_group" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 7
}