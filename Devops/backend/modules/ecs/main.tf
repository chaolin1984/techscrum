#############################################################################################################
#                                    ecsTaskExecutionRole 
############################################################################################################
data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      },
      Effect = "Allow",
      Sid    = ""
    }]
  })
}

resource "aws_iam_policy" "ecs_base_policy" {
  name        = "ECSBasePolicy"
  description = "Base policy for ECS to pull images and log events"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      Resource = "*",
      Effect   = "Allow"
    }]
  })
}

resource "aws_iam_policy" "ssm_app_policy" {
  name        = "SSMAppPolicy"
  description = "Policy for SSM parameters under /techscrum/"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action   = "ssm:GetParameter",
      Resource = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/techscrum/*",
      Effect   = "Allow"
    }]
  })
}
resource "aws_iam_role_policy_attachment" "ecs_base_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_base_policy.arn
}

resource "aws_iam_role_policy_attachment" "ecs_ssm_app_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ssm_app_policy.arn
}

data "aws_ssm_parameters_by_path" "config_params" {
  path = "/techscrum/"
}

data "aws_ssm_parameter" "ssm_params" {
  for_each = toset(data.aws_ssm_parameters_by_path.config_params.names)
  name     = each.value
}
locals {
  ssm_values = {
    for name, param in data.aws_ssm_parameter.ssm_params : name => param.value
  }
}
#######################################################################################################################
#                                               Create ECS
#######################################################################################################################
resource "aws_ecs_cluster" "cluster_uat" {
  name               = "${var.app_name}-ecs-cluster-${var.app_environment_uat}"
  capacity_providers = ["FARGATE"]
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  tags = {
    Name        = "${var.app_name}-ecs-cluster-${var.app_environment_uat}"
    Environment = var.app_environment_uat
  }
}

resource "aws_cloudwatch_log_group" "log_group_uat" {
  name = "${var.app_name}-log-group-${var.app_environment_uat}"
  tags = {
    Name        = "${var.app_name}-log-group-${var.app_environment_uat}"
    Environment = var.app_environment_uat
  }
}

resource "aws_ecs_task_definition" "task_uat" {
  family                   = "${var.app_name}-task-denifition-${var.app_environment_uat}"
  network_mode             = "awsvpc"
  cpu                      = "1024" # equivalent to 1 vCPU
  memory                   = "3072" # equivalent to 3GB
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name      = "${var.app_name}-container-${var.app_environment_uat}",
      image     = "${var.repository_url}:latest",
      cpu       = 0,
      memory    = 300,
      essential = true,
      portMappings = [
        {
          containerPort = 8000,
          hostPort      = 8000,
          protocol      = "tcp"
        }
      ],
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8000/api/v2/healthcheck || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 0
      },
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.log_group_uat.name
          "awslogs-region"        = "ap-southeast-2",
          "awslogs-stream-prefix" = "${var.app_name}-${var.app_environment_uat}"
        }
      },
      environment = [
        { name = "ENVIRONMENT", value = local.ssm_values["/techscrum/ENVIRONMENT"] },
        { name = "NAME", value = local.ssm_values["/techscrum/NAME"] },
        { name = "PORT", value = local.ssm_values["/techscrum/PORT"] },
        { name = "API_PREFIX", value = local.ssm_values["/techscrum/API_PREFIX"] },
        { name = "AWS_REGION", value = local.ssm_values["/techscrum/REGION"] },
        { name = "AWS_ACCESS_KEY_ID", value = local.ssm_values["/techscrum/ACCESS_KEY_ID"] },
        { name = "AWS_SECRET_ACCESS_KEY", value = local.ssm_values["/techscrum/SECRET_ACCESS_KEY"] },
        { name = "ACCESS_SECRET", value = local.ssm_values["/techscrum/ACCESS_SECRET"] },
        { name = "EMAIL_SECRET", value = local.ssm_values["/techscrum/EMAIL_SECRET"] },
        { name = "FORGET_SECRET", value = local.ssm_values["/techscrum/FORGET_SECRET"] },
        { name = "LIMITER", value = local.ssm_values["/techscrum/LIMITER"] },
        { name = "MAIN_DOMAIN", value = local.ssm_values["/techscrum/MAIN_DOMAIN"] },
        { name = "PUBLIC_CONNECTION", value = local.ssm_values["/techscrum/PUBLIC_CONNECTION"] },
        { name = "TENANTS_CONNECTION", value = local.ssm_values["/techscrum/TENANTS_CONNECTION"] },
        { name = "STRIPE_PRIVATE_KEY", value = local.ssm_values["/techscrum/STRIPE_PRIVATE_KEY"] },
        { name = "STRIPE_WEBHOOK_SECRET", value = local.ssm_values["/techscrum/STRIPE_WEBHOOK_SECRET"] }
      ]
    }
  ])
  tags = {
    Name        = "${var.app_name}-task-denifition-${var.app_environment_uat}"
    Environment = var.app_environment_uat
  }
  depends_on = [
    aws_iam_role_policy_attachment.ecs_base_policy_attachment,
    aws_iam_role_policy_attachment.ecs_ssm_app_policy_attachment
  ]
}

///create uat ecs servcie
resource "aws_ecs_service" "service_uat" {
  name            = "${var.app_name}-ecs-service-${var.app_environment_uat}"
  cluster         = aws_ecs_cluster.cluster_uat.id
  task_definition = aws_ecs_task_definition.task_uat.arn
  desired_count   = var.task_desired_count
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = var.uat_public_subnet_ids
    assign_public_ip = true
    security_groups  = [var.uat_service_sg_id]
  }
  tags = {
    Name        = "${var.app_name}-ecs-service-${var.app_environment_uat}"
    Environment = var.app_environment_uat
  }
}

// create prod cluster
resource "aws_ecs_cluster" "cluster_prod" {
  name               = "${var.app_name}-ecs-cluster-${var.app_environment_prod}"
  capacity_providers = ["FARGATE"]
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  tags = {
    Name        = "${var.app_name}-ecs-cluster-${var.app_environment_prod}"
    Environment = var.app_environment_prod
  }
}

resource "aws_cloudwatch_log_group" "log_group_prod" {
  name = "${var.app_name}-log-group-${var.app_environment_prod}"
  tags = {
    Name        = "${var.app_name}-log-group-${var.app_environment_prod}"
    Environment = var.app_environment_prod
  }
}

resource "aws_ecs_task_definition" "task_prod" {
  family                   = "${var.app_name}-task-denifition-${var.app_environment_prod}"
  network_mode             = "awsvpc"
  cpu                      = "1024" # equivalent to 1 vCPU
  memory                   = "3072" # equivalent to 3GB
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "${var.app_name}-container-${var.app_environment_prod}",
      image     = "${var.repository_url}:latest",
      cpu       = 0,
      memory    = 300,
      essential = true,
      portMappings = [
        {
          containerPort = 8000,
          hostPort      = 8000,
          protocol      = "tcp"
        }
      ],
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8000/api/v2/healthcheck || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 0
      },
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.log_group_prod.name
          "awslogs-region"        = "ap-southeast-2",
          "awslogs-stream-prefix" = "${var.app_name}-${var.app_environment_prod}"
        }
      },
      environment = [
        { name = "ENVIRONMENT", value = local.ssm_values["/techscrum/ENVIRONMENT"] },
        { name = "NAME", value = local.ssm_values["/techscrum/NAME"] },
        { name = "PORT", value = local.ssm_values["/techscrum/PORT"] },
        { name = "API_PREFIX", value = local.ssm_values["/techscrum/API_PREFIX"] },
        { name = "AWS_REGION", value = local.ssm_values["/techscrum/REGION"] },
        { name = "AWS_ACCESS_KEY_ID", value = local.ssm_values["/techscrum/ACCESS_KEY_ID"] },
        { name = "AWS_SECRET_ACCESS_KEY", value = local.ssm_values["/techscrum/SECRET_ACCESS_KEY"] },
        { name = "ACCESS_SECRET", value = local.ssm_values["/techscrum/ACCESS_SECRET"] },
        { name = "EMAIL_SECRET", value = local.ssm_values["/techscrum/EMAIL_SECRET"] },
        { name = "FORGET_SECRET", value = local.ssm_values["/techscrum/FORGET_SECRET"] },
        { name = "LIMITER", value = local.ssm_values["/techscrum/LIMITER"] },
        { name = "MAIN_DOMAIN", value = local.ssm_values["/techscrum/MAIN_DOMAIN"] },
        { name = "PUBLIC_CONNECTION", value = local.ssm_values["/techscrum/PUBLIC_CONNECTION"] },
        { name = "TENANTS_CONNECTION", value = local.ssm_values["/techscrum/TENANTS_CONNECTION"] },
        { name = "STRIPE_PRIVATE_KEY", value = local.ssm_values["/techscrum/STRIPE_PRIVATE_KEY"] },
        { name = "STRIPE_WEBHOOK_SECRET", value = local.ssm_values["/techscrum/STRIPE_WEBHOOK_SECRET"] }
      ]
    }
  ])
  tags = {
    Name        = "${var.app_name}-task-denifition-${var.app_environment_prod}"
    Environment = var.app_environment_prod
  }
  depends_on = [
    aws_iam_role_policy_attachment.ecs_base_policy_attachment,
    aws_iam_role_policy_attachment.ecs_ssm_app_policy_attachment
  ]
}

///create ecs servcie
resource "aws_ecs_service" "service_prod" {
  name            = "${var.app_name}-ecs-service-${var.app_environment_prod}"
  cluster         = aws_ecs_cluster.cluster_prod.id
  task_definition = aws_ecs_task_definition.task_prod.arn
  desired_count   = var.task_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.prod_private_subnet_ids
    assign_public_ip = true
    security_groups  = [var.prod_service_sg_id]
  }

  load_balancer {
    target_group_arn = var.tg_prod_arn
    container_name   = "${var.app_name}-container-${var.app_environment_prod}"
    container_port   = var.port
  }
  depends_on = [var.listener_arn]
  tags = {
    Name        = "${var.app_name}-ecs-service-${var.app_environment_prod}"
    Environment = var.app_environment_prod
  }
}
#######################################################################################################################
#                                               Auto Scale Group
#######################################################################################################################
//Auto scale for UAT 
resource "aws_appautoscaling_target" "scale_target_uat" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.cluster_uat.name}/${aws_ecs_service.service_uat.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.task_min_count
  max_capacity       = var.task_max_count
}

resource "aws_appautoscaling_policy" "scale_up_policy_uat" {
  name               = "${aws_ecs_service.service_uat.name}-scale-up-policy-${var.app_environment_uat}"
  service_namespace  = aws_appautoscaling_target.scale_target_uat.service_namespace
  resource_id        = aws_appautoscaling_target.scale_target_uat.resource_id
  scalable_dimension = aws_appautoscaling_target.scale_target_uat.scalable_dimension

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
}

resource "aws_appautoscaling_policy" "scale_down_policy_uat" {
  name               = "${aws_ecs_service.service_uat.name}-scale-down-policy-${var.app_environment_uat}"
  service_namespace  = aws_appautoscaling_target.scale_target_uat.service_namespace
  resource_id        = aws_appautoscaling_target.scale_target_uat.resource_id
  scalable_dimension = aws_appautoscaling_target.scale_target_uat.scalable_dimension

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_high_uat" {
  alarm_name          = "${aws_ecs_service.service_uat.name}-cpu-high-${var.app_environment_uat}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "5"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "80"
  alarm_actions       = [aws_appautoscaling_policy.scale_up_policy_uat.arn]

  dimensions = {
    ClusterName = aws_ecs_cluster.cluster_uat.name
    ServiceName = aws_ecs_service.service_uat.name
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_low_uat" {
  alarm_name          = "${aws_ecs_service.service_uat.name}-cpu-low-${var.app_environment_uat}"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "5"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "20"
  alarm_actions       = [aws_appautoscaling_policy.scale_down_policy_uat.arn]

  dimensions = {
    ClusterName = aws_ecs_cluster.cluster_uat.name
    ServiceName = aws_ecs_service.service_uat.name
  }
}

///Auto scale for PROD

resource "aws_appautoscaling_target" "scale_target_prod" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.cluster_prod.name}/${aws_ecs_service.service_prod.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.task_min_count
  max_capacity       = var.task_max_count
}

resource "aws_appautoscaling_policy" "scale_up_policy_prod" {
  name               = "${aws_ecs_service.service_prod.name}-scale-up-policy-${var.app_environment_prod}"
  service_namespace  = aws_appautoscaling_target.scale_target_prod.service_namespace
  resource_id        = aws_appautoscaling_target.scale_target_prod.resource_id
  scalable_dimension = aws_appautoscaling_target.scale_target_prod.scalable_dimension

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
}

resource "aws_appautoscaling_policy" "scale_down_policy_prod" {
  name               = "${aws_ecs_service.service_prod.name}-scale-down-policy-${var.app_environment_prod}"
  service_namespace  = aws_appautoscaling_target.scale_target_prod.service_namespace
  resource_id        = aws_appautoscaling_target.scale_target_prod.resource_id
  scalable_dimension = aws_appautoscaling_target.scale_target_prod.scalable_dimension

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_high_prod" {
  alarm_name          = "${aws_ecs_service.service_prod.name}-cpu-high-${var.app_environment_prod}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "5"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "80"
  alarm_actions       = [aws_appautoscaling_policy.scale_up_policy_prod.arn]

  dimensions = {
    ClusterName = aws_ecs_cluster.cluster_prod.name
    ServiceName = aws_ecs_service.service_prod.name
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_low_prod" {
  alarm_name          = "${aws_ecs_service.service_prod.name}-cpu-low-${var.app_environment_prod}"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "5"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "20"
  alarm_actions       = [aws_appautoscaling_policy.scale_down_policy_prod.arn]

  dimensions = {
    ClusterName = aws_ecs_cluster.cluster_prod.name
    ServiceName = aws_ecs_service.service_prod.name
  }
}