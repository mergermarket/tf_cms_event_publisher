resource "aws_dynamodb_table" "events" {
  name             = "${var.events_table}"
  billing_mode     = "PAY_PER_REQUEST"
  hash_key         = "aggregateId"
  range_key        = "rowKey"
  stream_enabled   = true
  stream_view_type = "NEW_IMAGE"

  point_in_time_recovery {
    enabled = true
  }

  attribute {
    name = "aggregateId"
    type = "S"
  }

  attribute {
    name = "rowKey"
    type = "S"
  }

  tags {
    Environment = "${var.env}"
  }

    global_secondary_index {
    name               = "${var.events_table}-index"
    hash_key           = "aggregateId"
    range_key          = "rowKey"
    read_capacity      = "${var.snapshots_read_capacity}"
    write_capacity     = "${var.snapshots_write_capacity}"
    projection_type    = "INCLUDE"
    non_key_attributes = ["id"]
  }
}

module "backup-selection-events" {
  source       = "mergermarket/centralised-aws-backup-selection/acuris"
  version      = "1.0.0"
  identifier   = "${var.events_table}-backup"
  database_arn = "${aws_dynamodb_table.events.arn}"
  plan_name    = "default"
}

resource "aws_dynamodb_table" "snapshots" {
  name           = "${var.snapshots_table}"
  read_capacity  = "${var.snapshots_read_capacity}"
  write_capacity = "${var.snapshots_write_capacity}"
  hash_key       = "aggregateId"
  range_key      = "id"

  point_in_time_recovery {
    enabled = true
  }

  attribute {
    name = "aggregateId"
    type = "S"
  }

  attribute {
    name = "id"
    type = "S"
  }
  
  tags {
    Environment = "${var.env}"
  }
}

module "backup-selection-snapshots" {
  source       = "mergermarket/centralised-aws-backup-selection/acuris"
  version      = "1.0.0"
  identifier   = "${var.snapshots_table}-backup"
  database_arn = "${aws_dynamodb_table.snapshots.arn}"
  plan_name    = "default"
}

resource "aws_sns_topic" "sns_topic" {
  name = "${var.env}-${var.cms_name}-cms-publish-topic"
}

resource "aws_iam_role" "iam_for_publish_lambda" {
  name               = "${var.env}-iam-for-${var.cms_name}-cms-publish-lambda"
  assume_role_policy = "${data.aws_iam_policy_document.iam_for_publish_lambda_policy.json}"
}

data "aws_iam_policy_document" "iam_for_publish_lambda_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "publish_lambda_policy" {
  name = "${var.env}-${var.cms_name}-cms-publish-lambda-policy"
  role = "${aws_iam_role.iam_for_publish_lambda.id}"

  policy = "${data.aws_iam_policy_document.publish_lambda_policy_document.json}"
}

data "aws_iam_policy_document" "publish_lambda_policy_document" {
  statement {
    actions = [
      "lambda:InvokeFunction",
    ]

    resources = [
      "${aws_lambda_function.cms_publish_lambda.arn}*",
    ]
  }

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:aws:logs:*:*:*",
    ]
  }

  statement {
    actions = [
      "dynamodb:DescribeStream",
      "dynamodb:GetRecords",
      "dynamodb:GetShardIterator",
      "dynamodb:ListStreams",
    ]

    resources = [
      "${aws_dynamodb_table.events.arn}/stream/*",
    ]
  }

  statement {
    actions = [
      "sns:Publish",
    ]

    resources = [
      "${aws_sns_topic.sns_topic.arn}",
    ]
  }
}

resource "aws_lambda_event_source_mapping" "publish_lambda_event_source" {
  batch_size        = 100
  event_source_arn  = "${aws_dynamodb_table.events.stream_arn}"
  enabled           = true
  function_name     = "${aws_lambda_function.cms_publish_lambda.arn}"
  starting_position = "TRIM_HORIZON"
}

data "archive_file" "init" {
  type        = "zip"
  source_file = "${path.module}/publishEvent.js"
  output_path = "${path.module}/publishEvent.zip"
}

resource "aws_lambda_function" "cms_publish_lambda" {
  filename      = "${path.module}/publishEvent.zip"
  function_name = "${var.env}-${var.cms_name}-cms-publish-lambda-function"
  role          = "${aws_iam_role.iam_for_publish_lambda.arn}"
  handler       = "publishEvent.handleEvents"
  runtime       = "nodejs8.10"

  environment {
    variables = {
      SNS_TOPIC = "${aws_sns_topic.sns_topic.arn}"
    }
  }
}
