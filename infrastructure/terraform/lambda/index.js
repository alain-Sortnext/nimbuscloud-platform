exports.handler = async (event) => {
    console.log("Notification dispatcher running");
    console.log("Event:", JSON.stringify(event, null, 2));
    
    // Process SQS messages
    if (event.Records) {
        for (const record of event.Records) {
            console.log("Processing record:", record.body);
        }
    }
    
    return {
        statusCode: 200,
        body: JSON.stringify({
            message: "Success"
        })
    };
};
