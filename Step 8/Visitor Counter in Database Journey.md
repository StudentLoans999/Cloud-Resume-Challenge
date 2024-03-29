My journey to complete Step 8 (using AWS DynamoDB to store the Visitor Counter's count).

Below I listed the actions I took

## Table of Contents
- [Summary](#Summary)
- [Action 1](#Action-1)
- [Action 2](#Action-2)
- [Action 3](#Action-3)
- [Action 4](#Action-4)
- [Action 5](#Action-5)
- [Action 6](#Action-6)

***
## Summary
**Action 1 - Started the AWS course: Developing with Amazon DynamoDB**

**Action 2 - Created Cloud9 and all the other services needed for it**

**Action 3 - Installed AWS SDK for Python in Cloud9**

**Action 4 - Set up DynamoDB Local**

**Action 5 - Interacted with DynamoDB using AWS CLI**

**Action 6 - Interacted with DynamoDB using AWS SDK**
***

## Action 1 
I started with taking the Developing with Amazon DynamoDB course on AWS https://explore.skillbuilder.aws/learn/course/1525/play;state=%255Bobject%2520Object%255D;autoplay=0

Actions 2-# are about that. Actions #+1 are about after I finished the course and worked on using DynamoDB for the CRC. 
***
## Action 2
All of the steps below I used with help from this (https://docs.aws.amazon.com/cloud9/latest/user-guide/vpc-settings.html?icmpid=docs_ac9_console#vpc-settings-requirements-subnets-view)

Created VPC (10.0.0.0/16)

![image](https://github.com/StudentLoans999/AWS/assets/77641113/8ff30d1a-9553-4759-a5d1-671b51406917)

Created Subnet (10.0.0.0/24)

![image](https://github.com/StudentLoans999/AWS/assets/77641113/1caa9e71-f0ec-4460-8609-04f9342947d9)


Associated Route Table with subnet

![image](https://github.com/StudentLoans999/AWS/assets/77641113/7f4ea8c4-2543-42ce-b76b-3b88a8e74400)


Created Internet Gateway and Attached it to the VPC

![image](https://github.com/StudentLoans999/AWS/assets/77641113/8e1cb95a-95b3-4045-b32e-0966e518ef54)

Edited Route Table to have a Route to igw (0.0.0.0/0 to igw)

![image](https://github.com/StudentLoans999/AWS/assets/77641113/09f75742-51eb-4994-bb07-51a20f2ffa08)

Created Cloud9 IED with the VPC and Subnet config from above

![image](https://github.com/StudentLoans999/AWS/assets/77641113/d5d032ed-8f72-4c93-969f-438c701b39c3)
***
## Action 3
In Cloud9, I ran "sudo yum -y update" in order to update packages (none were needed)

![image](https://github.com/StudentLoans999/AWS/assets/77641113/d4925fa8-8248-43fe-baf8-264828399805)

Then I ran "sudo pip3 install boto3" to install the AWS SDK for Python 

![image](https://github.com/StudentLoans999/AWS/assets/77641113/3d0ed25f-780a-4b92-8479-d5978542bf56)
***
## Action 4
In Cloud9, below is what I did for setting up DynamoDB Local

Installed Docker to the system by running "docker pull amazon/dynamodb-local" (amazon/dynamodb-local is the image)

![image](https://github.com/StudentLoans999/AWS/assets/77641113/f245bb3b-ecd6-4385-9f10-b4e5d317d6f7)

Started dynamoDB by running "docker run -p 8000:8000 amazon/dynamodb-local" http://localhost:8000/ is the endpoint url (8000 is the port)

![image](https://github.com/StudentLoans999/AWS/assets/77641113/d9b533e9-eb97-41d3-a1fc-80ca297b5418)

Put in access key by using "aws onfigure" (must have AWS CLI installed) - I already had my access key info configured.
***
## Action 5
In Cloud9, below is the AWS CLI I did for interacting with DynamoDB (here is a good source of info https://docs.aws.amazon.com/cli/latest/reference/dynamodb/create-table.html)

KeyType of HASH is the partition key (unique) ; KeyType of RANGE is the sort key (optional, can only have one) ; Having both makes the unique identifier the combination of the HASH and RANGE.

AttributeType of N is number ; AttributeType of S is string.

Other parameters that can be used: --region us-east 1 ; (if using DyanmoDB LocaL) --endpoint-url http://localhost:8000

<br></br>
**To Create a DynamoDB table :**

    aws dynamodb create-table ^

      --table-name Movies ^

      --key-schema ^

       AttributeName=year,KeyType=HASH ^

       AttributeName=title,KeyType=RANGE ^

       --attribute-definitions ^

       AttributeName=year,AttributeType=N ^

       AttributeName=title,AttributeType=S ^

       --billing-mode PAY_PER_REQUEST
  
  ![image](https://github.com/StudentLoans999/AWS/assets/77641113/cf218796-e881-4b85-8fee-489a600f74f5)

<br></br>
**To Write an item into a DynamoDB table :**

    aws dynamodb put-item ^

      --table-name Movies ^

      --item "{\"year\": {\"N\": \"1900\"}, \"title\": {\"S\": \"Example 1\"}}"
  
  ![image](https://github.com/StudentLoans999/AWS/assets/77641113/2833c230-45b6-4852-a87d-46a16879d07c)

<br></br>
**To Query a DynamoDB table (uses the partition key to retrieve specific items)  :** 

    aws dynamodb query ^

      --table-name Movies ^

      --key-condition-expression "#y = :yr" ^

      --projection-expression "title" ^

      --expression-attribute-names "{\"#y\":\"year\"}" ^

      --expression-attribute-values "{\":yr\":{\"N\":\"1985\"}}"
  
![image](https://github.com/StudentLoans999/AWS/assets/77641113/06f9c407-f8b9-449b-9ff8-192d102b590a)
  
<br></br>
**To Scan a DynamoDB table (reads the full table) :**

    aws dynamodb scan ^

      --table-name Movies ^

      --filter-expression "title = :name" ^

      --expression-attribute-values "{\":name\":{\"S\":\"Back to the Future\"}}" ^

      --return-consumed-capacity "TOTAL"
      
![image](https://github.com/StudentLoans999/AWS/assets/77641113/db830668-9853-4944-a691-d81b917fd960)
***
## Action 6
In Cloud9, below is the AWS SDK for Python I did for interacting with DynamoDB (here is a good source of info https://docs.aws.amazon.com/code-library/latest/ug/python_3_dynamodb_code_examples.html)
    
Use this code to import python :

    import boto3
    ddb = boto3.client('dynamodb')
    ddb.describe_limits()

All of the code snippets below are saved as individual python files, which can be run in Cloud9 by doing :

    python3 fil;ename.py

**To Create a DynamoDB table (createTable.py) :**

    import boto3


    def create_movie_table(dynamodb=None):
        if not dynamodb:
            dynamodb = boto3.resource('dynamodb')

            # Explicitly specify a region
            #dynamodb = boto3.resource('dynamodb',region_name='us-west-2')

            # Use a DynamoDB Local endpoint
            #dynamodb = boto3.resource('dynamodb',endpoint_url="http://localhost:8000")

        table = dynamodb.create_table(
            TableName='Movies',
            KeySchema=[
                {
                    'AttributeName': 'year',
                    'KeyType': 'HASH'  # Partition key
                },
                {
                    'AttributeName': 'title',
                    'KeyType': 'RANGE'  # Sort key
                }
            ],
            AttributeDefinitions=[
                {
                    'AttributeName': 'year',
                    'AttributeType': 'N'
                },
                {
                    'AttributeName': 'title',
                    'AttributeType': 'S'
                },

            ],
            ProvisionedThroughput={
                'ReadCapacityUnits': 10,
                'WriteCapacityUnits': 10
            }
        )
        return table


    if __name__ == '__main__':
        movie_table = create_movie_table()
        print("Table Name:", movie_table.table_name)
        print("Table status:", movie_table.table_status)
        print("Table ARN:", movie_table.table_arn)
        client = boto3.client('dynamodb')
        respons = client.describe_table(TableName='Movies')
        print("Table desc:", respons)

<br></br>
**To Write an item into a DynamoDB table (loadMovieData.py) :**
    
    from decimal import Decimal
    import json
    import boto3


    def load_movies(movies, dynamodb=None):
        if not dynamodb:
            dynamodb = boto3.resource('dynamodb')

            # Explicitly specify a region
            #dynamodb = boto3.resource('dynamodb',region_name='us-west-2')

            # Use a DynamoDB Local endpoint
            #dynamodb = boto3.resource('dynamodb',endpoint_url="http://localhost:8000")

        table = dynamodb.Table('Movies')
        for movie in movies:
            year = int(movie['year'])
            title = movie['title']
            print("Adding movie:", year, title)
            table.put_item(Item=movie)


    if __name__ == '__main__':
        with open("moviedata.json") as json_file:
            movie_list = json.load(json_file, parse_float=Decimal)
        load_movies(movie_list)    
 
<br></br>
**To Write multiple items into a DynamoDB table :**
    
    table = dynamodb.Table('Movies')
    
    with table.batch_writer() as batch:
        batch.put_item(
            Item={
                'year': 1900,
                'title': 'Example 10',
            }
        )
        batch.put_item(
            Item={
                'year': 1990,
                'title': 'Example 11',
            }
        )
         
<br></br>
**To update items into a DynamoDB table :**
 
    def update_movie(title, year, rating, plot, actors, dynamodb=None):
    if not dynamodb:
        dynamodb = boto3,resouce('dynamodb', endpoint_url="http://localhost:8000")

    table = dynamodb.Table('Movies')

    response = table.update_item(
            Key={
                'year': year,
                'title': title
            },
            UpdateExpression="set info.rating=:r, info.plot=:p, info.actors=:a",
            ExpressionAttributeValues={
                ':r': Decimal(rating),
                ':p': plot,
                ':a': actors
            },
            ReturnValues="UPDATED_NEW"
    )
    return response
    
<br></br>
**To Scan a DynamoDB table (scanTable.py) :**
 
    from pprint import pprint
    import boto3
    from boto3.dynamodb.conditions import Key


    def scan_movies(year_range, display_movies, dynamodb=None):
        if not dynamodb:
            dynamodb = boto3.resource('dynamodb')

            # Explicitly specify a region
            #dynamodb = boto3.resource('dynamodb',region_name='us-west-2')

            # Use a DynamoDB Local endpoint
            #dynamodb = boto3.resource('dynamodb',endpoint_url="http://localhost:8000")

        table = dynamodb.Table('Movies')
        scan_kwargs = {
            'FilterExpression': Key('year').between(*year_range),
            'ProjectionExpression': "#yr, title, info.rating",
            'ExpressionAttributeNames': {"#yr": "year"}
        }

        done = False
        start_key = None
        while not done:
            if start_key:
                scan_kwargs['ExclusiveStartKey'] = start_key
            response = table.scan(**scan_kwargs)
            display_movies(response.get('Items', []))
            start_key = response.get('LastEvaluatedKey', None)
            done = start_key is None


    if __name__ == '__main__':
        def print_movies(movies):
            for movie in movies:
                print(f"\n{movie['year']} : {movie['title']}")
                pprint(movie['info'])

        query_range = (1950, 1959)
        print(
            f"Scanning for movies released from {query_range[0]} to {query_range[1]}...")
        scan_movies(query_range, print_movies)
        
<br></br>
**To Query a DynamoDB table (queryTable.py) :** 

    import boto3
    from boto3.dynamodb.conditions import Key


    def query_movies(year, dynamodb=None):
        if not dynamodb:
            dynamodb = boto3.resource('dynamodb')

            # Explicitly specify a region
            #dynamodb = boto3.resource('dynamodb',region_name='us-west-2')

            # Use a DynamoDB Local endpoint
            #dynamodb = boto3.resource('dynamodb',endpoint_url="http://localhost:8000")

        table = dynamodb.Table('Movies')
        response = table.query(
            KeyConditionExpression=Key('year').eq(year)
        )
        return response['Items']


    if __name__ == '__main__':
        query_year = 1985
        print(f"Movies from {query_year}")
        movies = query_movies(query_year)
        for movie in movies:
            print(movie['year'], ":", movie['title'])
