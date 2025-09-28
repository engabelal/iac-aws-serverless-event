// Handler: POST /register
// Purpose: Insert a new attendee if not already registered for the same event.

const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, GetCommand, PutCommand } = require("@aws-sdk/lib-dynamodb");

const TABLE = process.env.TABLE_NAME;
const docClient = DynamoDBDocumentClient.from(new DynamoDBClient({}));

exports.handler = async (event) => {
  try {
    const body = typeof event.body === "string" ? JSON.parse(event.body) : (event.body || {});

    if (!body.email || !body.event) {
      return {
        statusCode: 400,
        headers: { "Access-Control-Allow-Origin": "*", "Content-Type": "text/plain" },
        body: "Missing email or event",
      };
    }

    const existing = await docClient.send(new GetCommand({
      TableName: TABLE,
      Key: { email: body.email, event: body.event },
    }));

    if (existing.Item) {
      return {
        statusCode: 400,
        headers: { "Access-Control-Allow-Origin": "*", "Content-Type": "text/plain" },
        body: "Already registered for this event",
      };
    }

    await docClient.send(new PutCommand({
      TableName: TABLE,
      Item: {
        email: body.email,
        event: body.event,
        name: body.name || "",
        phone: body.phone || "",
        won: "no",
        created_at: new Date().toISOString(),
      },
      ConditionExpression: "attribute_not_exists(email) AND attribute_not_exists(event)",
    }));

    return {
      statusCode: 200,
      headers: { "Access-Control-Allow-Origin": "*", "Content-Type": "text/plain" },
      body: "Thanks for registering",
    };
  } catch (err) {
    return {
      statusCode: 500,
      headers: { "Access-Control-Allow-Origin": "*", "Content-Type": "text/plain" },
      body: err.message || "Server error",
    };
  }
};
