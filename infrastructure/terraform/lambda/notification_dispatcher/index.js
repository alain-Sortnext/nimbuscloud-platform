const { SESClient, SendEmailCommand } = require("@aws-sdk/client-ses");

const sesClient = new SESClient({});
const FROM_EMAIL = process.env.SES_FROM_EMAIL;

exports.handler = async (event) => {
  console.log(`Received ${event.Records?.length || 0} SQS message(s)`);

  for (const record of event.Records || []) {
    const message = JSON.parse(record.body);

    console.log("Processing notification:", {
      type: message.type,
      hasCustomerEmail: Boolean(message.customer_email),
    });

    if (message.type === "payment_confirmed" && message.customer_email) {
      await sesClient.send(
        new SendEmailCommand({
          Source: FROM_EMAIL,
          Destination: {
            ToAddresses: [message.customer_email],
          },
          Message: {
            Subject: {
              Data: "Payment Confirmed - NimbusCloud",
            },
            Body: {
              Text: {
                Data: `Your payment of £${(
                  Number(message.amount || 0) / 100
                ).toFixed(2)} has been confirmed.`,
              },
            },
          },
        })
      );

      console.log("Payment confirmation email sent");
    } else {
      console.log("Notification skipped: unsupported or incomplete message");
    }
  }

  return {
    statusCode: 200,
    processed: event.Records?.length || 0,
  };
};
