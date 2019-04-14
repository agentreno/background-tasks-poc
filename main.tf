# SNS setup
resource "aws_sns_topic" "background_task_events" {
    name = "background_task_events"
}

resource "aws_sns_topic_subscription" "lambda_processor_sub" {
    topic_arn = "${aws_sns_topic.background_task_events.arn}"
    protocol = "lambda"
    endpoint = "${aws_lambda_function.lambda_processor.arn}"

    filter_policy = <<FILTER
{
    "event": ["task_for_lambda"]
}
FILTER
}

# Lambda setup
resource "aws_iam_role" "lambda_processor" {
    name = "background_task_lambda_processor"

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

resource "aws_lambda_permission" "allow_sns" {
    statement_id = "AllowExecutionFromSNS"
    action = "lambda:invokeFunction"
    function_name = "${aws_lambda_function.lambda_processor.function_name}"
    principal = "sns.amazonaws.com"
    source_arn = "${aws_sns_topic.background_task_events.arn}"
}

data "template_file" "lambda_policy" {
    template = "${file("lambda_policy.tpl")}"
}

resource "aws_iam_role_policy" "lambda_processor_policy" {
    name = "background_tasks_lambda_processor_policy"
    role = "${aws_iam_role.lambda_processor.id}"
    policy = "${data.template_file.lambda_policy.rendered}"
}

resource "aws_lambda_function" "lambda_processor" {
    function_name = "background_task_lambda_processor"
    filename = "lambda_processor/lambda_processor.zip"
    role = "${aws_iam_role.lambda_processor.arn}"
    handler = "main.handler"
    runtime = "python3.7"
}

# Step function setup
resource "aws_iam_role" "step_function_trigger" {
    name = "background_task_step_function_trigger"

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

data "template_file" "step_function_trigger_policy" {
    template = "${file("step_function_trigger_policy.tpl")}"
}

resource "aws_iam_role_policy" "step_function_trigger_policy" {
    name = "background_tasks_step_function_trigger_policy"
    role = "${aws_iam_role.step_function_trigger.id}"
    policy = "${data.template_file.step_function_trigger_policy.rendered}"
}

resource "aws_lambda_function" "step_function_trigger" {
    function_name = "background_task_step_function_trigger"
    filename = "step_function_trigger/step_function_trigger.zip"
    role = "${aws_iam_role.step_function_trigger.arn}"
    handler = "main.handler"
    runtime = "python3.7"
}
