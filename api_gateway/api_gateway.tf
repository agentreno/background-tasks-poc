variable "region" {}

# IAM policies and roles
resource "aws_iam_role_policy" "apigateway" {
    name = "StepFunctionsAPI"
    role = "${aws_iam_role.apigateway.id}"

    policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "states:*"
            ],
            "Resource": "*"
        }
    ]
}
POLICY
}

resource "aws_iam_role" "apigateway" {
    name = "apigateway"

    assume_role_policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "apigateway.amazonaws.com"
            },
            "Effect": "Allow"
        }
    ]
}
POLICY
}

# API and resource definitions
resource "aws_api_gateway_rest_api" "rest_api" {
    name = "StepFunctionsAPI"
}

resource "aws_api_gateway_resource" "succeed" {
    rest_api_id = "${aws_api_gateway_rest_api.rest_api.id}"
    parent_id = "${aws_api_gateway_rest_api.rest_api.root_resource_id}"
    path_part = "succeed"
}

resource "aws_api_gateway_method" "succeed" {
    rest_api_id = "${aws_api_gateway_rest_api.rest_api.id}"
    resource_id = "${aws_api_gateway_resource.succeed.id}"
    http_method = "GET"
    request_parameters = {
        "method.request.querystring.taskToken" = true
    }
    request_validator_id = "${aws_api_gateway_request_validator.succeed.id}"
    authorization = "NONE"
}

resource "aws_api_gateway_request_validator" "succeed" {
    name = "Validate querystring params"
    rest_api_id = "${aws_api_gateway_rest_api.rest_api.id}"
    validate_request_parameters = true
}

resource "aws_api_gateway_method_response" "200" {
    rest_api_id = "${aws_api_gateway_rest_api.rest_api.id}"
    resource_id = "${aws_api_gateway_resource.succeed.id}"
    http_method = "GET"
    status_code = "200"
}

resource "aws_api_gateway_method_response" "400" {
    rest_api_id = "${aws_api_gateway_rest_api.rest_api.id}"
    resource_id = "${aws_api_gateway_resource.succeed.id}"
    http_method = "GET"
    status_code = "400"
}

resource "aws_api_gateway_integration_response" "success" {
    rest_api_id = "${aws_api_gateway_rest_api.rest_api.id}"
    resource_id = "${aws_api_gateway_resource.succeed.id}"
    http_method = "GET"
    selection_pattern = "200"
    status_code = "200"
}

resource "aws_api_gateway_integration_response" "error" {
    rest_api_id = "${aws_api_gateway_rest_api.rest_api.id}"
    resource_id = "${aws_api_gateway_resource.succeed.id}"
    http_method = "GET"
    selection_pattern = "4\\d{2}"
    status_code = "400"
    response_templates {
        "application/json" = <<EOF
{
    "error": "Invalid task token"
}
EOF
    }
}

resource "aws_api_gateway_integration" "stepfunction" {
    rest_api_id = "${aws_api_gateway_rest_api.rest_api.id}"
    resource_id = "${aws_api_gateway_resource.succeed.id}"
    http_method = "GET"
    type = "AWS"
    uri = "arn:aws:apigateway:${var.region}:states:action/SendTaskSuccess"
    integration_http_method = "POST"
    credentials = "${aws_iam_role.apigateway.arn}"

    # Wraps the incoming event into the format expected by Kinesis stream
    passthrough_behavior = "WHEN_NO_TEMPLATES"
    request_templates {
        "application/json" = <<EOF
{
   "output": "\"Approve link was clicked.\"",
   "taskToken": "$input.params('taskToken')"
}
EOF
    }
}

# Deployment
resource "aws_api_gateway_deployment" "main" {
    depends_on = [
        "aws_api_gateway_method.succeed",
        "aws_api_gateway_integration.stepfunction"
    ]
    rest_api_id = "${aws_api_gateway_rest_api.rest_api.id}"
    stage_name = "respond"

    # Without this, changes to the API gateway methods/integrations etc. do not
    # get deployed, this unused variable forces this resource to be updated 
    # when any change has been made to API gateway configuration
    variables {
        code_hash = "${md5(file("api_gateway/api_gateway.tf"))}"
    }
}

output "api_gateway_url" {
    value = "${aws_api_gateway_deployment.main.invoke_url}"
}
