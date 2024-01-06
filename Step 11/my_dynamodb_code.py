import boto3

def update_view_count(table_name, item_id, increment):
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(table_name)

    response = table.update_item(
        Key={"id": item_id},
        UpdateExpression='SET view_count = view_count + :incr',
        ExpressionAttributeValues={':incr': {"N": str(increment)}},
        ReturnValues="UPDATED_NEW"
    )

    return response
