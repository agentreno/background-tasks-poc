'use strict';
console.log('Loading function');
const aws = require('aws-sdk');
const stepfunctions = new aws.StepFunctions();
const ses = new aws.SES();
exports.handler = (event, context, callback) => {
    
    var taskParams = {
        activityArn: process.env.activityArn
    };
    
    stepfunctions.getActivityTask(taskParams, function(err, data) {
        if (err) {
            console.log(err, err.stack);
            context.fail('An error occured while calling getActivityTask.');
        } else {
            if (!data.input) {
                // No activities scheduled
                context.succeed('No activities received after 60 seconds.');
            } else {
                console.log(data);
                console.log(process.env.apiGatewayUrl + '/succeed?taskToken=' + encodeURIComponent(data.taskToken));
                var input = JSON.parse(data.input);
                var emailParams = {
                    Destination: {
                        ToAddresses: [
                            input.managerEmailAddress
                            ]
                    },
                    Message: {
                        Subject: {
                            Data: 'Your Approval Needed for Promotion!',
                            Charset: 'UTF-8'
                        },
                        Body: {
                            Html: {
                                Data: 'Hi!<br />' +
                                    input.employeeName + ' has been nominated for promotion!<br />' +
                                    'Can you please approve:<br />' +
                                    process.env.apiGatewayUrl + '/succeed?taskToken=' + encodeURIComponent(data.taskToken) + '<br />' +
                                    'Or reject:<br />' +
                                    process.env.apiGatewayUrl + '/fail?taskToken=' + encodeURIComponent(data.taskToken),
                                Charset: 'UTF-8'
                            }
                        }
                    },
                    Source: input.managerEmailAddress,
                    ReplyToAddresses: [
                            input.managerEmailAddress
                        ]
                };
                /*    
                ses.sendEmail(emailParams, function (err, data) {
                    if (err) {
                        console.log(err, err.stack);
                        context.fail('Internal Error: The email could not be sent.');
                    } else {
                        console.log(data);
                        context.succeed('The email was successfully sent.');
                    }
                });*/
                context.succeed('Skipped email');
            }
        }
    });
};
