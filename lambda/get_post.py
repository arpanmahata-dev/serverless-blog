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
    Get a single blog post by ID
    """
    print(f"Event received: {json.dumps(event)}")
    
    try:
        # Get post ID from path parameters
        post_id = event.get('pathParameters', {}).get('id')
        
        if not post_id:
            return error_response(400, 'Post ID is required')
        
        print(f"Fetching post: {post_id}")
        
        # Get item from DynamoDB
        response = table.get_item(Key={'id': post_id})
        
        if 'Item' not in response:
            return error_response(404, 'Post not found')
        
        print(f"Post found: {post_id}")
        
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET,DELETE',
                'Content-Type': 'application/json'
            },
            'body': json.dumps(response['Item'], cls=DecimalEncoder)
        }
        
    except Exception as e:
        print(f"Error fetching post: {str(e)}")
        return error_response(500, f'Error fetching post: {str(e)}')

def error_response(status_code, message):
    """Return error response with CORS headers"""
    return {
        'statusCode': status_code,
        'headers': {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET,DELETE',
            'Content-Type': 'application/json'
        },
        'body': json.dumps({'error': message})
    }

class DecimalEncoder(json.JSONEncoder):
    """Helper class to convert DynamoDB Decimal types to JSON"""
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)