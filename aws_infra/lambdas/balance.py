import boto3
from boto3.dynamodb.conditions import Key
import json


def lambda_handler(event, context):
    try:
        dynamodb = boto3.resource("dynamodb")
        table = dynamodb.Table("Commodities")

        query_params = event.get("queryStringParameters", {})
        country = query_params.get("country")
        year = int(query_params.get("year")) if query_params.get("year") else None

        if not country and not year:
            raise ValueError("Missing required parameter: 'country' and 'year'")

        if country:
            query_result = table.query(
                KeyConditionExpression=Key("pk").eq(f"type=Balance?country={country}")
            )
            formatted_data = [
                {
                    "year": str(item["data"]["year"]),
                    "total_imports": item["data"]["total_imports"],
                    "total_exports": item["data"]["total_exports"],
                    "total_commodity_imports": item["data"]["total_commodity_imports"],
                    "total_commodity_exports": item["data"]["total_commodity_exports"],
                }
                for item in query_result["Items"]
            ]

        elif year:
            query_result = table.query(
                IndexName="TypeIndex",
                KeyConditionExpression=Key("type").eq("Balance") & Key("sk").eq(year),
            )
            formatted_data = [
                {
                    "country": item["data"]["country"],
                    "total_commodity_imports": item["data"]["total_commodity_imports"],
                    "total_commodity_exports": item["data"]["total_commodity_exports"],
                }
                for item in query_result["Items"]
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
