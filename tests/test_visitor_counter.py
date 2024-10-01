import json
import pytest
from moto import mock_dynamodb
import boto3
import sys
import os

# Add the parent directory to sys.path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Set AWS_REGION environment variable for the test
os.environ['AWS_REGION'] = 'us-east-1'

from lambda_function.visitor_counter import lambda_handler

@mock_dynamodb
def test_lambda_handler():
    # Create mock DynamoDB table
    dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
    table = dynamodb.create_table(
        TableName='resume-challenge',
        KeySchema=[{'AttributeName': 'id', 'KeyType': 'HASH'}],
        AttributeDefinitions=[{'AttributeName': 'id', 'AttributeType': 'S'}],
        BillingMode='PAY_PER_REQUEST'
    )

    # Initialize the counter
    table.put_item(Item={'id': '0', 'views': 0})

    # Test the lambda function
    event = {}
    context = {}
    response = lambda_handler(event, context)

    assert response['statusCode'] == 200
    body = json.loads(response['body'])
    assert 'views' in body
    assert body['views'] == 1

    # Test it again to make sure the counter increments
    response = lambda_handler(event, context)
    body = json.loads(response['body'])
    assert body['views'] == 2