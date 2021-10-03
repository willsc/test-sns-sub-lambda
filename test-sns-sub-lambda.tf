resource "aws_sns_topic" "my_first_sns_topic" {
  name = "test_topic"
}

resource "aws_sns_topic_policy" "my_sns_topic_policy" {
  arn = aws_sns_topic.my_first_sns_topic.arn
  policy = data.aws_iam_policy_document.my_custom_sns_policy_document.json
}

data "aws_iam_policy_document" "my_custom_sns_policy_document" {
  policy_id = "__default_policy_ID"

  statement {
    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"

      values = [
        "897086669335",
      ]
    }

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      aws_sns_topic.my_first_sns_topic.arn,
    ]

    sid = "__default_statement_ID"
  }
}


module "lambda" {
  source           = "moritzzimmer/lambda/aws"
  version          = "5.16.0"

  filename         = "lambda_function.zip"
  function_name    = "lambda_function"
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.6"
  source_code_hash = filebase64sha256("${path.module}/lambda_function.zip")
}


resource "aws_lambda_permission" "allow_invocation_from_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.my_first_sns_topic.arn
}



resource "aws_sns_topic_subscription" "sns-topic" {
  endpoint = module.lambda.arn
  protocol = "lambda"
  topic_arn = aws_sns_topic.my_first_sns_topic.arn
}