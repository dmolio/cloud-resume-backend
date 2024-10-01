import json
import boto3
from botocore.exceptions import ClientError
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('resume-challenge')

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
