aws sns publish \
    --topic-arn "arn:aws:sns:eu-west-1:461321663140:background_task_events" \
    --message "{}" \
    --message-attributes '{"event": {"DataType": "String", "StringValue": "task_for_step_function"}}'
