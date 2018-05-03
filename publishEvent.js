
var AWS = require("aws-sdk");
var sns = new AWS.SNS();

exports.handleEvents = (event, context, callback) => {

    if (!process.env.SNS_TOPIC) {
      callback ("SNS_TOPIC not defined")
    }

    event.Records.forEach((record) => {
      if (record.eventName === 'INSERT') {
        const newEvent = record.dynamodb.NewImage;
        const params = {
          Message: JSON.stringify(newEvent),
          TopicArn: process.env.SNS_TOPIC
        }
        sns.publish(params, function(err, data) {
          if (err) {
              console.error("Unable to send message. Error JSON:", JSON.stringify(err, null, 2));
          } else {
              console.log("Results from sending message: ", JSON.stringify(data, null, 2));
          }
        })
    }})

    callback(null, `Successfully processed ${event.Records.length} records.`);
}
