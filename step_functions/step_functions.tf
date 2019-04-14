variable "api_gateway_url" {}
variable "region" {}

resource "aws_sfn_activity" "manual_step" {
	name = "ManualStep"
}

resource "aws_lambda_function" "manual_step_worker" {
	function_name = "ManualStepActivityWorker"
	filename = "activity_worker/activity_worker.zip"
	role = "${aws_iam_role.manual_step_worker.arn}"
	handler = "index.handler"
	runtime = "nodejs8.10"

	environment {
		variables {
			activityArn = "${aws_sfn_activity.manual_step.id}"
			apiGatewayUrl = "${var.api_gateway_url}"
		}
	}
}

resource "aws_iam_role" "manual_step_worker" {
	name = "ManualStepActivityWorker"
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

resource "aws_iam_role_policy" "manual_step_worker" {
	name = "ManualStepActivityWorker"
	role = "${aws_iam_role.manual_step_worker.id}"
	policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        },
        {
            "Effect": "Allow",
            "Action": "states:GetActivityTask",
            "Resource": "arn:aws:states:*:*:activity:ManualStep"
        },
        {
            "Effect": "Allow",
            "Action": "ses:SendEmail",
            "Resource": "*"
        }
    ]
}
EOF
}

# Import state machine from template
data "template_file" "state_machine_definition" {
    template = "${file("step_functions/state_machine.json")}"

    vars {
		"activity_arn" = "${aws_sfn_activity.manual_step.id}"
		"lambda_arn" = "${aws_lambda_function.manual_step_worker.arn}"
    }
}

# IAM policies and roles
resource "aws_iam_role_policy" "state_machine" {
    name = "PromotionApproval"
    role = "${aws_iam_role.state_machine.id}"

    policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "lambda:*",
                "states:*"
            ],
            "Resource": "*"
        }
    ]
}
POLICY
}

resource "aws_iam_role" "state_machine" {
    name = "state_machine"

    assume_role_policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "states.${var.region}.amazonaws.com"
            },
            "Effect": "Allow"
        }
    ]
}
POLICY
}

resource "aws_sfn_state_machine" "state_machine" {
    name = "PromotionApproval"
    role_arn = "${aws_iam_role.state_machine.arn}"

    definition = "${data.template_file.state_machine_definition.rendered}"
}

output "state_machine_arn" {
    value = "${aws_sfn_state_machine.state_machine.id}"
}

