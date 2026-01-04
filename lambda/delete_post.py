import json
import boto3
import os

# Initialize DynamoDB
dynamodb = boto3.resource('dynamodb')
table_name = os.environ.get('TABLE_NAME', 'blog-posts')
table = dynamodb.Table(table_name)

def lambda_handler(event, context):
    """
    Delete a blog post by ID
    """
    print(f"Event received: {json.dumps(event)}")
    
    try:
        # Get post ID from path parameters
        post_id = event.get('pathParameters', {}).get('id')
        
        if not post_id:
            return error_response(400, 'Post ID is required')
        
        print(f"Deleting post: {post_id}")
        
        # Delete item from DynamoDB
        table.delete_item(Key={'id': post_id})
        
        print(f"Post deleted successfully: {post_id}")
        
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET,DELETE',
                'Content-Type': 'application/json'
            },
            'body': json.dumps({
                'message': 'Post deleted successfully',
                'id': post_id
            })
        }
        
    except Exception as e:
        print(f"Error deleting post: {str(e)}")
        return error_response(500, f'Error deleting post: {str(e)}')

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