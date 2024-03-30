import boto3
import json


def lambda_handler(event, context):
    try:
        dynamodb = boto3.resource("dynamodb")
        table = dynamodb.Table("Commodities")

        query_params = event.get("queryStringParameters", {})
        commodity = query_params.get("commodity")

        if not commodity:
            raise ValueError("Missing required parameter: 'commodity'")

        query_result = table.get_item(
            Key={"pk": f"type=Prices?commodity={commodity}", "sk": 0}
        )
        data = query_result.get("Item", {}).get("data", [])
        formatted_data = [
            {"date": str(item["date"]), "price": str(item["price"])} for item in data
        ]

        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*",
            },
            "body": json.dumps({"success": True, "data": formatted_data}),
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*",
            },
            "body": json.dumps({"success": False, "error": str(e)}),
        }
