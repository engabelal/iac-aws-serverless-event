// Handler: GET /count
// Purpose: Return total number of registrations (across all events).

const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, ScanCommand } = require("@aws-sdk/lib-dynamodb");

const TABLE = process.env.TABLE_NAME;
const docClient = DynamoDBDocumentClient.from(new DynamoDBClient({}));

exports.handler = async () => {
  try {
    let count = 0;
    let ExclusiveStartKey;

    do {
      const resp = await docClient.send(new ScanCommand({
        TableName: TABLE,
        ExclusiveStartKey,
      }));

      count += resp.Count || 0;
      ExclusiveStartKey = resp.LastEvaluatedKey;
    } while (ExclusiveStartKey);

    return {
      statusCode: 200,
      headers: { "Access-Control-Allow-Origin": "*", "Content-Type": "application/json" },
      body: JSON.stringify(count),
    };
  } catch (err) {
    return {
      statusCode: 500,
      headers: { "Access-Control-Allow-Origin": "*", "Content-Type": "application/json" },
      body: JSON.stringify({ error: err.message || "Server error" }),
    };
  }
};
