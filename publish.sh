aws sns publish \
    --topic-arn "arn:aws:sns:eu-west-1:461321663140:background_task_events" \
    --message "not_for_lambda" \
    --message-attributes '{"event": {"DataType": "String", "StringValue": "not_for_lambda"}}'
