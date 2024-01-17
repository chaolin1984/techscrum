resource "aws_iam_role" "handler_lambda_exec" {
  name = "handler-lambda"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "handler_lambda_policy" {
  role       = aws_iam_role.handler_lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "handler_lambda_policy2" {
  role       = aws_iam_role.handler_lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_lambda_function" "handler" {
  function_name = "s3-backup"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.handler.key

  runtime = "nodejs14.x"
  handler = "index.handler"

  timeout = 180

  source_code_hash = data.archive_file.handler.output_base64sha256

  role = aws_iam_role.handler_lambda_exec.arn
}


resource "aws_cloudwatch_log_group" "handler_lambda" {
  name = "/aws/lambda/${aws_lambda_function.handler.function_name}"
}

data "archive_file" "handler" {
  type        = "zip"
  source_dir  = "../code"
  output_path = "../code/index.zip"
}

resource "aws_s3_object" "handler" {
  bucket = aws_s3_bucket.lambda_bucket.id
  key    = "index.zip"
  source = data.archive_file.handler.output_path
  etag   = filemd5(data.archive_file.handler.output_path)
}


resource "aws_cloudwatch_event_rule" "lambda_scheduled_trigger" {
  name                = "lambda_scheduled_trigger"
  description         = "Triggers Lambda function at 10 PM Brisbane time daily"
  schedule_expression = "cron(0 12 * * ? *)"
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.lambda_scheduled_trigger.name
  arn       = aws_lambda_function.handler.arn
  target_id = "hander"
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_check_foo" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.handler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda_scheduled_trigger.arn
}