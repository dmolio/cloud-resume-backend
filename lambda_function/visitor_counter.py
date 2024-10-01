import json
import boto3
import os
from botocore.exceptions import ClientError

def get_dynamodb_resource():
    if 'DYNAMODB_ENDPOINT_URL' in os.environ:
        return boto3.resource('dynamodb', endpoint_url=os.environ['DYNAMODB_ENDPOINT_URL'])
    return boto3.resource('dynamodb')

# Get the table name from environment variable or use a default
TABLE_NAME = os.environ.get('DYNAMODB_TABLE_NAME', 'resume-challenge')

dynamodb = get_dynamodb_resource()
table = dynamodb.Table(TABLE_NAME)

def lambda_handler(event, context):
    try:
        response = table.update_item(
            Key={'id': '0'},
            UpdateExpression='SET #views = if_not_exists(#views, :start) + :inc',
            ExpressionAttributeNames={'#views': 'views'},
            ExpressionAttributeValues={':inc': 1, ':start': 0},
            ReturnValues='UPDATED_NEW'
        )
        views = int(response['Attributes']['views'])  # Convert Decimal to int
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'views': views})
        }
    except ClientError as e:
        print(f"Error: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }