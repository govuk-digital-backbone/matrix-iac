data "archive_file" "sqlmgr" {
  type        = "zip"
  source_dir  = "${path.module}/sql-manager/"
  output_path = "sqlmgr-lambda.zip"
}

resource "aws_lambda_function" "sqlmgr" {
  filename         = "sqlmgr-lambda.zip"
  function_name    = "${local.task_name}-sqlmgr"
  handler          = "main.lambda_handler"
  runtime          = "python3.13"
  role             = aws_iam_role.sqlmgr.arn
  source_code_hash = data.archive_file.sqlmgr.output_base64sha256

  memory_size = 512
  timeout     = 120

  environment {
    variables = {
      DB_HOST       = aws_rds_cluster.db.endpoint
      DB_ADMIN_USER = local.database_username
      DB_ADMIN_PASS = local.database_password
      SYNAPSE_DB    = local.database_name
    }
  }

  vpc_config {
    subnet_ids         = data.aws_subnets.private_subnets.ids
    security_group_ids = [aws_security_group.sqlmgr.id]
  }
}

resource "aws_lambda_invocation" "sqlmgr" {
  function_name = aws_lambda_function.sqlmgr.function_name
  input = jsonencode({
    source_code_hash = data.archive_file.sqlmgr.output_base64sha256
  })
  lifecycle_scope = "CRUD"
}

resource "aws_iam_role" "sqlmgr" {
  name               = "${local.task_name}-sqlmgr"
  assume_role_policy = data.aws_iam_policy_document.sqlmgr_assume_role_policy.json
}

resource "aws_iam_policy" "sqlmgr" {
  name   = "${local.task_name}-sqlmgr"
  policy = data.aws_iam_policy_document.sqlmgr_policy.json
}

resource "aws_iam_role_policy_attachment" "sqlmgr" {
  policy_arn = aws_iam_policy.sqlmgr.arn
  role       = aws_iam_role.sqlmgr.name
}

data "aws_iam_policy_document" "sqlmgr_assume_role_policy" {
  version = "2012-10-17"

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "sqlmgr_policy" {
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
}

resource "aws_security_group" "sqlmgr" {
  vpc_id = var.vpc_id

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
