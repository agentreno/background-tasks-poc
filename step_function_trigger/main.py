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
    # TODO: Possibility of multiple records? Try setting in topic subscription
    # that sends only message body and not metadata?
    message_id = event['Records'][0]['Sns']['MessageId']

    # Get message body from event to hand to state machine input
    # TODO: Possibility of multiple records? Try setting in topic subscription
    # that sends only message body and not metadata?
    message_body = event['Records'][0]['Sns']['Message']

    client = boto3.client('stepfunctions')
    response = client.start_execution(
        stateMachineArn=step_function_arn,
        name=message_id,
        input=message_body
    )

    print(response)

    return
