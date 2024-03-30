import boto3
from boto3.dynamodb.conditions import Key
import json


def lambda_handler(event, context):
    try:
        dynamodb = boto3.resource("dynamodb")
        table = dynamodb.Table("Commodities")

        query_params = event.get("queryStringParameters", {})
        commodity = query_params.get("commodity")
        country = query_params.get("country")
        year = int(query_params.get("year")) if query_params.get("year") else None

        if (
            not (commodity and country)
            and not (commodity and year)
            and not (country and year)
            and not year
        ):
            raise ValueError(
                "Missing required parameters: 'commodity', 'country', or 'year'"
            )

        if commodity and country:
            query_result = table.query(
                KeyConditionExpression=Key("pk").eq(
                    f"type=Production?commodity={commodity}?country={country}"
                )
            )
            formatted_data = [
                {
                    "amount": item["data"]["amount"],
                    "year": str(item["data"]["year"]),
                    "metric": item["data"]["metric"],
                }
                for item in query_result["Items"]
            ]

        elif commodity and year:
            query_result = table.query(
                IndexName="TypeAndCommodityIndex",
                KeyConditionExpression=Key("type_and_commodity").eq(
                    f"type=Production?commodity={commodity}"
                )
                & Key("sk").eq(year),
            )
            formatted_data = [
                {
                    "country": item["data"]["country"],
                    "amount": item["data"]["amount"],
                    "metric": item["data"]["metric"],
                    "share": str(item["data"]["share"]),
                }
                for item in query_result["Items"]
            ]

        elif country and year:
            query_result = table.query(
                IndexName="TypeAndCountryIndex",
                KeyConditionExpression=Key("type_and_country").eq(
                    f"type=Production?country={country}"
                )
                & Key("sk").eq(year),
            )
            formatted_data = [
                {
                    "commodity": item["data"]["commodity"],
                    "amount": item["data"]["amount"],
                    "metric": item["data"]["metric"],
                    "rank": str(item["data"]["rank"]),
                    "share": str(item["data"]["share"]),
                }
                for item in query_result["Items"]
            ]

        elif year:
            query_result = table.query(
                IndexName="TypeIndex",
                KeyConditionExpression=Key("type").eq("Production")
                & Key("sk").eq(year),
            )
            formatted_data = [
                {
                    "country": item["data"]["country"],
                    "commodity": item["data"]["commodity"],
                    "share": str(item["data"]["share"]),
                }
                for item in query_result["Items"]
                if "share" in item["data"]
                and item["data"]["share"]
                and float(item["data"]["share"]) > 30
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
