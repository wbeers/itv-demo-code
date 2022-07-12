import os
import boto3
import time
import json
import logging

code_pipeline = boto3.client('codepipeline')

def lambda_handler(event, context):

    client = boto3.client('cloudfront')
    invalidation = client.create_invalidation(
        DistributionId= os.environ['distribution'],
        InvalidationBatch={
            'Paths': {
                'Quantity': 1,
                'Items': [
                    '/*',
                ]
            },
            'CallerReference': str(time.time())
        }
    )

    response = code_pipeline.put_job_success_result(
        jobId=event['CodePipeline.job']['id']
    )
    return response
