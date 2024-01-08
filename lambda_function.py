import boto3
import json

def lambda_handler(event, context):
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('Terraform-Table-CRC')

    # Update the item in DynamoDB table (if_not_exists sets view_count to 0 if it doesn't exist AKA being run for the first time)
    response = table.update_item(
        Key={"id": "1"},
        UpdateExpression='SET view_count = if_not_exists(view_count, :start) + :incr',
        ExpressionAttributeValues={':incr': 1, ':start': 0},
        ReturnValues="UPDATED_NEW"
    )

    # Construct and return the response
    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': 'Function Executed Successfully!',
            'dynamodbResponse': response
        })
    }
