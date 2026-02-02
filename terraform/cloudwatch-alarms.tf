resource "aws_cloudwatch_metric_alarm" "ecs_service_running_tasks" {
  alarm_name        = "${var.project}-ecs-service-unavailable"
  alarm_description = "ECS service is unavailable (no running tasks)"

  namespace           = "AWS/ECS"
  metric_name         = "CPUUtilization"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 2
  threshold           = 0
  comparison_operator = "LessThanOrEqualToThreshold"

  dimensions = {
    ClusterName = aws_ecs_cluster.cluster.name
    ServiceName = aws_ecs_service.service.name
  }

  treat_missing_data = "breaching"
}

resource "aws_cloudwatch_metric_alarm" "ecs_service_high_cpu" {
  alarm_name          = "${var.project}-ecs-high-cpu"
  alarm_description   = "High CPU usage detected on ECS service"

  namespace           = "AWS/ECS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 3
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    ClusterName = aws_ecs_cluster.cluster.name
    ServiceName = aws_ecs_service.service.name
  }

  treat_missing_data = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "ecs_service_high_memory" {
  alarm_name          = "${var.project}-ecs-high-memory"
  alarm_description   = "High memory usage detected on ECS service"

  namespace           = "AWS/ECS"
  metric_name         = "MemoryUtilization"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 3
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    ClusterName = aws_ecs_cluster.cluster.name
    ServiceName = aws_ecs_service.service.name
  }

  treat_missing_data = "notBreaching"
}
