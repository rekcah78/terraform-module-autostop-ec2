data "aws_iam_policy_document" "ec2_onoff" {
  statement {
    sid = "1"

    actions = [
      "ec2:StartInstances",
      "ec2:StopInstances",
      "ec2:Describe*",
    ]

    resources = [
      "*",
    ]
  }
}

data "aws_iam_policy_document" "lambda_log" {
  statement {
    sid = "1"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role" "iam_for_lambda_autostop" {
  name = "iam_for_lambda_autostop-${var.name}"

  assume_role_policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [
		{
		"Action": "sts:AssumeRole",
		"Principal": {
				"Service": "lambda.amazonaws.com"
		},
		"Effect": "Allow",
		"Sid": ""
		}
	]
}
EOF
}

resource "aws_iam_role_policy" "lambda-autostop-ec2_onoff" {
  name = "autostop-allow-ec2-${var.name}"
  role = "${aws_iam_role.iam_for_lambda_autostop.name}"

  policy = "${data.aws_iam_policy_document.ec2_onoff.json}"
}

resource "aws_iam_role_policy" "lambda-autostop-lambda_log" {
  name = "autostop-allow-log-${var.name}"
  role = "${aws_iam_role.iam_for_lambda_autostop.name}"

  policy = "${data.aws_iam_policy_document.lambda_log.json}"
}

data "archive_file" "autostop-start" {
  type        = "zip"
  source_file = "${path.module}/start.py"
  output_path = "${path.module}/start.zip"
}

data "archive_file" "autostop-stop" {
  type        = "zip"
  source_file = "${path.module}/stop.py"
  output_path = "${path.module}/stop.zip"
}

resource "aws_lambda_function" "autostop-start" {
  filename         = "${path.module}/start.zip"
  function_name    = "autostop-start-${var.name}"
  role             = "${aws_iam_role.iam_for_lambda_autostop.arn}"
  handler          = "start.start"
  source_code_hash = "${data.archive_file.autostop-start.output_base64sha256}"
  runtime          = "python2.7"
  timeout	   = "${var.timeout}"
  memory_size	   = "${var.memory_size}"

  environment {
    variables = {
      FILTERS = "${var.filters_start}"
    }
  }
  tags = "${local.tags}"
}

resource "aws_lambda_function" "autostop-stop" {
  filename         = "${path.module}/stop.zip"
  function_name    = "autostop-stop-${var.name}"
  role             = "${aws_iam_role.iam_for_lambda_autostop.arn}"
  handler          = "stop.stop"
  source_code_hash = "${data.archive_file.autostop-stop.output_base64sha256}"
  runtime          = "python2.7"
  timeout	   = "${var.timeout}"
  memory_size	   = "${var.memory_size}"

  environment {
    variables = {
      FILTERS = "${var.filters_stop}"
    }
  }
  tags = "${local.tags}"
}

resource "aws_cloudwatch_log_group" "log_autostop-stop" {
  name              = "/aws/lambda/autostop-stop-${var.name}"
  retention_in_days = "7"
}

resource "aws_cloudwatch_log_group" "log_autostop-start" {
  name              = "/aws/lambda/autostop-start-${var.name}"
  retention_in_days = "7"
}

resource "aws_lambda_permission" "cloudwatch-autostop-start" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.autostop-start.arn}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.lambda_autostop_start.arn}"
}

resource "aws_lambda_permission" "cloudwatch-autostop-stop" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.autostop-stop.arn}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.lambda_autostop_stop.arn}"
}

resource "aws_cloudwatch_event_rule" "lambda_autostop_start" {
  name                = "autostop-start-${var.name}"
  schedule_expression = "${var.schedule_start}"
  is_enabled          = "${var.enabled_start}"
}

resource "aws_cloudwatch_event_rule" "lambda_autostop_stop" {
  name                = "autostop-stop-${var.name}"
  schedule_expression = "${var.schedule_stop}"
  is_enabled          = "${var.enabled_stop}"
}

resource "aws_cloudwatch_event_target" "lambda_autostop_start" {
  target_id = "autostop-start-${var.name}"
  rule      = "${aws_cloudwatch_event_rule.lambda_autostop_start.name}"
  arn       = "${aws_lambda_function.autostop-start.arn}"
}

resource "aws_cloudwatch_event_target" "lambda_autostop_stop" {
  target_id = "autostop-stop-${var.name}"
  rule      = "${aws_cloudwatch_event_rule.lambda_autostop_stop.name}"
  arn       = "${aws_lambda_function.autostop-stop.arn}"
}
