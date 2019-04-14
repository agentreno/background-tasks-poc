aws sns publish \
    --topic-arn "arn:aws:sns:eu-west-1:433473615199:background_task_events" \
    --message '{"managerEmailAddress": "dion.hopkinson@buto.tv", "employeeName": "Jim"}' \
    --message-attributes '{"event": {"DataType": "String", "StringValue": "task_for_step_function"}}'
