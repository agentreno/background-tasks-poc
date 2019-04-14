import os

import boto3


def handler(event, context):
    # Invoke step function based on env var
    step_function_arn = os.environ.get('STEP_FUNCTION_ARN', False)
    if not step_function_arn:
        raise EnvironmentError('No env var STEP_FUNCTION_ARN to trigger')

    # Get message ID from event to name execution
    # TODO: Handle case of no message ID, don't use static value in it's place
    # as execution name must be unique, this may stop further executions
    message_id = event.get('MessageId')

    # Get message body from event to hand to state machine input
    message_body = event.get('Message', '{}')

    client = boto3.client('stepfunctions')
    response = client.start_execution(
        stateMachineArn=step_function_arn,
        name=message_id,
        input=message_body
    )

    print(response)

    return
