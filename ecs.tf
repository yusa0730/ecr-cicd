# ECS
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.env}-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name      = "${var.project_name}-${var.env}-ecs-cluster"
    Env       = var.env
    ManagedBy = "Terraform"
  }
}

resource "aws_ecs_task_definition" "main" {
  family                   = "${var.project_name}-${var.env}-ecs-task-definition"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn # 必要に応じて分離

  container_definitions = jsonencode([
    {
      cpu       = 0
      memory    = 512
      name      = "nginx"
      image     = "${data.aws_caller_identity.self.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.project_name}-${var.env}-nginx:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80 # hostPortは省略可能
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-region"        = "${var.region}"
          "awslogs-group"         = "/ecs/${var.env}/web"
          "awslogs-stream-prefix" = "nginx"
        }
      }
    }
  ])

  tags = {
    Name      = "${var.project_name}-${var.env}-ecs-task-definition"
    Env       = var.env
    ManagedBy = "Terraform"
  }
}

resource "aws_ecs_service" "main" {
  name            = "${var.project_name}-${var.env}-ecs-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.id
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    assign_public_ip = false
    security_groups = [
      aws_security_group.ecs_sg.id
    ]

    subnets = [
      aws_subnet.protected_a.id
    ]
  }

  lifecycle {
    ignore_changes = [task_definition]
  }

  tags = {
    Name      = "${var.project_name}-${var.env}-ecs-service"
    Env       = var.env
    ManagedBy = "Terraform"
  }
}

resource "aws_cloudwatch_log_group" "for_ecs" {
  name              = "/ecs/${var.env}/web"
  retention_in_days = 180
}
