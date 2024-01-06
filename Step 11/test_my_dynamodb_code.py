import unittest
from moto import mock_dynamodb2
import boto3
from my_dynamodb_code import update_view_count

class TestDynamoDBOperations(unittest.TestCase):
    @mock_dynamodb2
    def test_update_view_count(self):
        # Set up mock DynamoDB
        dynamodb = boto3.resource('dynamodb', region_name='us-west-2')
        dynamodb.create_table(
            TableName='Table-CRC',
            KeySchema=[{'AttributeName': 'id', 'KeyType': 'HASH'}],
            AttributeDefinitions=[{'AttributeName': 'id', 'AttributeType': 'S'}],
            ProvisionedThroughput={'ReadCapacityUnits': 1, 'WriteCapacityUnits': 1}
        )

        # Mock update
        response = update_view_count('Table-CRC', '1', 1)
        
        # Check if the response is successful
        self.assertEqual(response['ResponseMetadata']['HTTPStatusCode'], 200)
        self.assertEqual(response['Attributes']['view_count'], 1)

if __name__ == '__main__':
    unittest.main()
