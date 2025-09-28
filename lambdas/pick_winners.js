// Handler: GET /pick_winners
// Purpose: Pick 3 random winners (across all events) and mark them as won="yes".
// Note: For production, filter by a specific event via query string.

const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const {
  DynamoDBDocumentClient,
  ScanCommand,
  UpdateCommand,
} = require("@aws-sdk/lib-dynamodb");
const crypto = require("crypto");

const TABLE = process.env.TABLE_NAME;
const docClient = DynamoDBDocumentClient.from(new DynamoDBClient({}));

exports.handler = async () => {
  try {
    let attendees = [];
    let ExclusiveStartKey;

    do {
      const resp = await docClient.send(
        new ScanCommand({
          TableName: TABLE,
          ExclusiveStartKey,
        })
      );

      attendees = attendees.concat(resp.Items || []);
      ExclusiveStartKey = resp.LastEvaluatedKey;
    } while (ExclusiveStartKey);

    if (attendees.length < 3) {
      return {
        statusCode: 200,
        headers: { "Access-Control-Allow-Origin": "*", "Content-Type": "application/json" },
        body: JSON.stringify({ winners: [], message: "Not enough registrations to pick 3 winners yet." }),
      };
    }

    const existingWinners = attendees.filter((a) => a.won === "yes");
    if (existingWinners.length >= 3) {
      return {
        statusCode: 200,
        headers: { "Access-Control-Allow-Origin": "*", "Content-Type": "application/json" },
        body: JSON.stringify({ winners: existingWinners.slice(0, 3), message: "Winners already selected." }),
      };
    }

    const eligible = attendees.filter((a) => a.won !== "yes");
    const needed = 3 - existingWinners.length;

    if (eligible.length < needed) {
      return {
        statusCode: 200,
        headers: { "Access-Control-Allow-Origin": "*", "Content-Type": "application/json" },
        body: JSON.stringify({ winners: existingWinners, message: "Not enough eligible attendees to complete 3 winners." }),
      };
    }

    const newWinners = sampleWithoutReplacement(eligible, needed);

    await Promise.all(
      newWinners.map((w) =>
        docClient.send(
          new UpdateCommand({
            TableName: TABLE,
            Key: { email: w.email, event: w.event },
            UpdateExpression: "SET won = :y",
            ExpressionAttributeValues: { ":y": "yes" },
          })
        )
      )
    );

    const totalWinners = existingWinners.concat(newWinners).slice(0, 3);

    return {
      statusCode: 200,
      headers: { "Access-Control-Allow-Origin": "*", "Content-Type": "application/json" },
      body: JSON.stringify({ winners: totalWinners, message: "New winners selected." }),
    };
  } catch (err) {
    return {
      statusCode: 500,
      headers: { "Access-Control-Allow-Origin": "*", "Content-Type": "application/json" },
      body: JSON.stringify({ error: err.message || "Server error" }),
    };
  }
};

function sampleWithoutReplacement(array, count) {
  const picked = [];
  const pool = [...array];
  for (let i = 0; i < count; i++) {
    const idx = crypto.randomInt(0, pool.length);
    picked.push(pool[idx]);
    pool.splice(idx, 1);
  }
  return picked;
}
