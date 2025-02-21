resource "aws_ecs_cluster" "main" {
  name = "alb-cognito-sample"
}

resource "aws_ecs_task_definition" "main" {
  family                   = "alb-cognito-sample"
  cpu                      = 256
  memory                   = 512
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  container_definitions    = file("./container_definitions.json")
}

resource "aws_ecs_service" "main" {
  name                              = "alb-cognito-sample"
  cluster                           = aws_ecs_cluster.main.arn
  task_definition                   = aws_ecs_task_definition.main.arn
  desired_count                     = 2
  launch_type                       = "FARGATE"
  platform_version                  = "1.3.0"
  health_check_grace_period_seconds = 60

  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.app.id]

    subnets = [for subnet in aws_subnet.private : subnet.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.http.arn
    container_name   = "alb-cognito-sample"
    container_port   = 80
  }

  depends_on = [aws_acm_certificate_validation.main, aws_lb.main, aws_lb_target_group.http]
}

resource "aws_security_group" "app" {
  name   = "app"
  vpc_id = aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "app_ipv4" {
  security_group_id            = aws_security_group.app.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.lb.id
}

