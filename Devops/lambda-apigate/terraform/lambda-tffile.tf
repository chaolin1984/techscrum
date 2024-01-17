
resource "aws_lambda_function" "tfbackup" {
  function_name = "tf-state-backup"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.tfbackup.key

  runtime = "nodejs14.x"
  handler = "tfstatebackup.handler"

  timeout = 180

  source_code_hash = data.archive_file.tfbackup.output_base64sha256

  role = aws_iam_role.handler_lambda_exec.arn
}


resource "aws_cloudwatch_log_group" "tfstate_lambda" {
  name = "/aws/lambda/${aws_lambda_function.tfbackup.function_name}"
}

data "archive_file" "tfbackup" {
  type        = "zip"
  source_dir  = "../tfstatecode"
  output_path = "../tfstatecode/tfstatebackup.zip"
}

resource "aws_s3_object" "tfbackup" {
  bucket = aws_s3_bucket.lambda_bucket.id
  key    = "tfstatebackup.zip"
  source = data.archive_file.tfbackup.output_path
  etag   = filemd5(data.archive_file.tfbackup.output_path)
}


resource "aws_cloudwatch_event_rule" "lambda_tfstate_backup_scheduled_trigger" {
  name                = "lambda_tfstate_backup_scheduled_trigger"
  description         = "Triggers Lambda function at 10 PM Brisbane time daily"
  schedule_expression = "cron(0 12 * * ? *)"
}

resource "aws_cloudwatch_event_target" "lambda_tfstate_target" {
  rule      = aws_cloudwatch_event_rule.lambda_tfstate_backup_scheduled_trigger.name
  arn       = aws_lambda_function.tfbackup.arn
  target_id = "hander"
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_tfstate_backup" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.tfbackup.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda_tfstate_backup_scheduled_trigger.arn
}