import boto3
import json

def lambda_handler(event, context):
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('Terraform-Table-CRC')

    # Update the item in DynamoDB table
    response = table.update_item(
        Key={"id": "1"},
        UpdateExpression='SET view_count = view_count + :incr',
        ExpressionAttributeValues={':incr': 1},
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
