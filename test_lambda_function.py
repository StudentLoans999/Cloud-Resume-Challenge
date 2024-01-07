import unittest
from moto import mock_dynamodb2
import boto3
from lambda_function import lambda_handler

class TestLambdaFunction(unittest.TestCase):
    @mock_dynamodb2
    def test_lambda_function(self):
        # Mocking DynamoDB
        dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
        dynamodb.create_table(
            TableName='Terraform-Table-CRC',
            KeySchema=[{'AttributeName': 'id', 'KeyType': 'HASH'}],
            AttributeDefinitions=[{'AttributeName': 'id', 'AttributeType': 'S'}],
            ProvisionedThroughput={'ReadCapacityUnits': 1, 'WriteCapacityUnits': 1}
        )

        # Mock event and context
        event = {}   # Example event
        context = {} # Example context

        # Invoke Lambda function
        response = lambda_handler(event, context)

        # Assert the response
        self.assertEqual(response['statusCode'], 200)
        self.assertIn('Function Executed Successfully!', response['body'])

if __name__ == '__main__':
    unittest.main()
