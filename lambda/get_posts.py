import json
import boto3
import os
from decimal import Decimal

# Initialize DynamoDB
dynamodb = boto3.resource('dynamodb')
table_name = os.environ.get('TABLE_NAME', 'blog-posts')
table = dynamodb.Table(table_name)

def lambda_handler(event, context):
    """
    Get all blog posts
    """
    print("Fetching all posts...")
    
    try:
        # Scan DynamoDB table
        response = table.scan()
        items = response.get('Items', [])
        
        # Handle pagination if there are more items
        while 'LastEvaluatedKey' in response:
            response = table.scan(ExclusiveStartKey=response['LastEvaluatedKey'])
            items.extend(response.get('Items', []))
        
        # Sort by created_at descending (newest first)
        items.sort(key=lambda x: x.get('created_at', ''), reverse=True)
        
        print(f"Found {len(items)} posts")
        
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET,DELETE',
                'Content-Type': 'application/json'
            },
            'body': json.dumps(items, cls=DecimalEncoder)
        }
        
    except Exception as e:
        print(f"Error fetching posts: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Content-Type': 'application/json'
            },
            'body': json.dumps({'error': f'Error fetching posts: {str(e)}'})
        }

class DecimalEncoder(json.JSONEncoder):
    """Helper class to convert DynamoDB Decimal types to JSON"""
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)