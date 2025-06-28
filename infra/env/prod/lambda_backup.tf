resource "aws_lambda_function" "url_checker" {
  function_name = "url-checker-${var.environment}"
  filename         = "../../../lambda/lambda.zip"
#  s3_bucket        = "mi-bucket-de-lambdas"
#  s3_key           = "lambda/lambda.zip"
  source_code_hash = filebase64sha256("../../../lambda/lambda.zip")  
#  source_code_hash = filebase64sha256("../../../lambda/lambda.zip")
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  role             = data.aws_iam_role.lab_role.arn
  timeout          = 10
}
