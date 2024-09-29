resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-${var.env}-ecs-task-execution-iar"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name      = "${var.project_name}-${var.env}-ecs-task-execution-role"
    Env       = var.env
    ManagedBy = "Terraform"
  }
}

resource "aws_iam_policy" "ecs_policy" {
  name = "${var.project_name}-${var.env}-ecs-iap"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = [
          "${aws_cloudwatch_log_group.for_ecs.arn}",
          "${aws_cloudwatch_log_group.for_ecs.arn}:*",
        ]
      }
    ]
  })

  tags = {
    Name      = "${var.project_name}-${var.env}-ecs-policy"
    Env       = var.env
    ManagedBy = "Terraform"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_attachment" {
  policy_arn = aws_iam_policy.ecs_policy.arn
  role       = aws_iam_role.ecs_task_execution_role.name
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.ecs_task_execution_role.name
}

## ======codebuild======
resource "aws_iam_role" "codebuild_role" {
  name = "${var.project_name}-${var.env}-codebuild-iar"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name      = "${var.project_name}-${var.env}-codebuild-iar"
    Env       = var.env
    ManagedBy = "Terraform"
  }
}

data "aws_iam_policy_document" "codebuild_iap" {
  statement {
    sid    = "S3"
    effect = "Allow"
    resources = [
      "${aws_s3_bucket.codepipeline_bucket.arn}",
      "${aws_s3_bucket.codepipeline_bucket.arn}/*"
    ]

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion"
    ]
  }

  statement {
    sid       = "AWSCloudWatchLogs"
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
  }

  statement {
    sid       = "ECR"
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
      "ecr:InitializeLayerGroup",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage"
    ]
  }

  statement {
    sid    = "githubconnection"
    effect = "Allow"
    resources = [
      "${aws_codestarconnections_connection.main.arn}"
    ]

    actions = [
      "codestar-connections:UseConnection"
    ]
  }
}

resource "aws_iam_policy" "codebuild_policy" {
  name   = "${var.project_name}-${var.env}-codebuild-iap"
  policy = data.aws_iam_policy_document.codebuild_iap.json
}

resource "aws_iam_role_policy_attachment" "codebuild_role_attachment" {
  policy_arn = aws_iam_policy.codebuild_policy.arn
  role       = aws_iam_role.codebuild_role.name
}


## ======codepipeline======
resource "aws_iam_role" "codepipeline_role" {
  name = "${var.project_name}-${var.env}-codepipeline-iar"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name      = "${var.project_name}-${var.env}-codepipeline-iar"
    Env       = var.env
    ManagedBy = "Terraform"
  }
}

data "aws_iam_policy_document" "codepipeline_iap" {
  statement {
    sid    = "S3"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObjectAcl",
      "s3:PutObject"
    ]
    resources = [
      "${aws_s3_bucket.codepipeline_bucket.arn}",
      "${aws_s3_bucket.codepipeline_bucket.arn}/*"
    ]
  }

  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
      "ecs:RegisterTaskDefinition",
      "ecs:UpdateService",
    ]
  }

  statement {
    sid    = "codebuild"
    effect = "Allow"
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild"
    ]
    resources = [
      "${aws_codebuild_project.main.arn}"
    ]
  }

  statement {
    sid    = "githubconnection"
    effect = "Allow"
    actions = [
      "codestar-connections:UseConnection"
    ]
    resources = [
      "${aws_codestarconnections_connection.main.arn}"
    ]
  }

  statement {
    effect = "Allow"
    resources = [
      "${aws_iam_role.ecs_task_execution_role.arn}"
    ]

    actions = ["iam:PassRole"]

    condition {
      test     = "StringLike"
      variable = "iam:PassedToService"

      values = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "codepipeline_policy" {
  name        = "${var.project_name}-${var.env}-codepipeline-iap"
  description = "IAM policy for CodePipeline"

  policy = data.aws_iam_policy_document.codepipeline_iap.json
}

resource "aws_iam_role_policy_attachment" "codepipeline_role_attachment" {
  policy_arn = aws_iam_policy.codepipeline_policy.arn
  role       = aws_iam_role.codepipeline_role.name
}
