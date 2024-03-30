import boto3
import json


def lambda_handler(event, context):
    try:
        dynamodb = boto3.resource("dynamodb")
        table = dynamodb.Table("Commodities")

        query_params = event.get("queryStringParameters", {})
        commodity = query_params.get("commodity")
        year = int(query_params.get("year")) if query_params.get("year") else None

        if not commodity or not year:
            raise ValueError("Missing required parameters: 'commodity' or 'year'")

        query_result = table.get_item(
            Key={"pk": f"type=Govinfo?commodity={commodity}", "sk": year}
        )
        formatted_data = {
            "prod_and_use": query_result["Item"]["data"]["prod_and_use"],
            "recycling": query_result["Item"]["data"]["recycling"],
            "events": query_result["Item"]["data"]["events"],
            "world_resources": query_result["Item"]["data"]["world_resources"],
            "substitutes": query_result["Item"]["data"]["substitutes"],
        }

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
