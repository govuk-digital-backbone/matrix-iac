data "archive_file" "cfgmgr" {
  type        = "zip"
  source_dir  = "${path.module}/config-manager"
  output_path = "cfgmgr-lambda.zip"

  depends_on = [
    local_file.homeserver_yaml
  ]
}

resource "aws_lambda_function" "cfgmgr" {
  filename         = "cfgmgr-lambda.zip"
  function_name    = "${local.task_name}-cfgmgr"
  handler          = "main.lambda_handler"
  runtime          = "python3.13"
  role             = aws_iam_role.cfgmgr.arn
  source_code_hash = data.archive_file.cfgmgr.output_base64sha256

  environment {
    variables = {
      DO_HS  = "False"
      DO_WEB = "True"
    }
  }

  vpc_config {
    subnet_ids         = data.aws_subnets.private_subnets.ids
    security_group_ids = [aws_security_group.cfgmgr.id]
  }

  #file_system_config {
  #  arn              = aws_efs_access_point.efs_ap_cfgmgr.arn
  #  local_mount_path = "/mnt/data"
  #}

  file_system_config {
    arn              = aws_efs_access_point.efs_ap_web.arn
    local_mount_path = "/mnt/web"
  }
}

resource "aws_lambda_invocation" "cfgmgr" {
  function_name = aws_lambda_function.cfgmgr.function_name
  input = jsonencode({
    source_code_hash = data.archive_file.cfgmgr.output_base64sha256
    print_efs_dir    = false
  })
  lifecycle_scope = "CRUD"
}

resource "aws_iam_role" "cfgmgr" {
  name               = "${local.task_name}-cfgmgr"
  assume_role_policy = data.aws_iam_policy_document.cfgmgr_assume_role_policy.json
}

resource "aws_iam_policy" "cfgmgr" {
  name   = "${local.task_name}-cfgmgr"
  policy = data.aws_iam_policy_document.cfgmgr_policy.json
}

resource "aws_iam_role_policy_attachment" "cfgmgr" {
  policy_arn = aws_iam_policy.cfgmgr.arn
  role       = aws_iam_role.cfgmgr.name
}

data "aws_iam_policy_document" "cfgmgr_assume_role_policy" {
  version = "2012-10-17"

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "cfgmgr_policy" {
  version = "2012-10-17"

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "lambda:InvokeFunction",
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeNetworkInterfaces"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite",
      "elasticfilesystem:ClientRootAccess"
    ]
    resources = [
      data.aws_efs_file_system.by_id.arn,
      "${data.aws_efs_file_system.by_id.arn}:access-point/*"
    ]
  }
}

resource "aws_security_group" "cfgmgr" {
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}