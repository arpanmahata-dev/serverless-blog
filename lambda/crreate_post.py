import json
import boto3
import uuid
from datetime import datetime
import os

# Initialize DynamoDB
dynamodb = boto3.resource('dynamodb')
table_name = os.environ.get('TABLE_NAME', 'blog-posts')
table = dynamodb.Table(table_name)

def lambda_handler(event, context):
    """
    Create a new blog post
    """
    print(f"Event received: {json.dumps(event)}")
    
    try:
        # Parse request body
        if isinstance(event.get('body'), str):
            body = json.loads(event['body'])
        else:
            body = event.get('body', {})
        
        # Validate required fields
        if not body.get('title'):
            return error_response(400, 'Title is required')
        
        if not body.get('content'):
            return error_response(400, 'Content is required')
        
        # Generate unique ID and timestamp
        post_id = str(uuid.uuid4())
        timestamp = datetime.now().isoformat()
        
        # Create post item
        item = {
            'id': post_id,
            'title': body['title'],
            'content': body['content'],
            'author': body.get('author', 'Anonymous'),
            'created_at': timestamp,
            'updated_at': timestamp,
            'status': 'published'
        }
        
        # Save to DynamoDB
        table.put_item(Item=item)
        
        print(f"Post created successfully: {post_id}")
        
        return success_response(item)
        
    except Exception as e:
        print(f"Error creating post: {str(e)}")
        return error_response(500, f'Error creating post: {str(e)}')

def success_response(data):
    """Return success response with CORS headers"""
    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET,DELETE',
            'Content-Type': 'application/json'
        },
        'body': json.dumps(data)
    }

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