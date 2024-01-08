import boto3
import json
from decimal import Decimal

def decimal_default(obj):
    if isinstance(obj, Decimal):
        return float(obj)
    raise TypeError

def lambda_handler(event, context):
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('Terraform-Table-CRC')

    # Update the item in DynamoDB table
    response = table.update_item(
        Key={"id": "1"},
        UpdateExpression='SET view_count = if_not_exists(view_count, :start) + :incr',
        ExpressionAttributeValues={':incr': 1, ':start': 0},
        ReturnValues="UPDATED_NEW"
    )

    # Convert DynamoDB response to JSON serializable format
    response_json = json.dumps(response, default=decimal_default)

    # Construct and return the response
    return {
        'statusCode': 200,
        'body': response_json
    }
