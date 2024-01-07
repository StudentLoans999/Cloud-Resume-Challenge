import boto3
import json

def lambda_handler(event, context):
  dynamodb = boto3.resouce('dynamodb')
  table = dynamodb.Table('Terraform-Table-CRC')

  response = table.update_item(Key={ "id":"1"}, 
                  UpdateExpression='SET view_count = view_count + :incr', 
                  ExpressionAttributeValues={':incr': {"N": "1"}} 
                  )
  return response
  
  return {
        'statusCode': 200,
        'body': json.dumps('Function Executed Successfully!')
    }
