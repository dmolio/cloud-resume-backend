import json
import boto3
import os

# Get the region from environment variable or default to 'us-east-1'
REGION = os.environ.get('AWS_REGION', 'us-east-1')

# Initialize the DynamoDB client with the region
dynamodb = boto3.resource('dynamodb', region_name=REGION)

# Get the table name from environment variable or use a default
TABLE_NAME = os.environ.get('DYNAMODB_TABLE_NAME', 'resume-challenge')

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
        return {
            'statusCode': 500,
            'headers': {
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': e.response['Error']['Message']})
        }
