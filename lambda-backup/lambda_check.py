import os
import requests
import boto3

def lambda_handler(event, context):
    alb = os.environ.get('ALB')
    aglb2 = os.environ.get('AGLB2')
    topic_arn = os.environ.get('SNS_TOPIC_ARN')

    endpoints = {
        f"http://{alb}:8080": "ALB",
        f"http://{aglb2}:8081": "AGLB2"
    }

    sns_client = boto3.client('sns')
    all_ok = True

    for url, name in endpoints.items():
        try:
            print(f"Checking {name} at {url}")
            response = requests.get(url, timeout=5)
            if response.status_code != 200:
                raise Exception(f"Status code: {response.status_code}")
        except Exception as e:
            all_ok = False
            sns_client.publish(
                TopicArn=topic_arn,
                Subject=f"[ALERTA] {name} no responde",
                Message=f"Fallo al chequear {name} ({url}): {str(e)}"
            )

    return "All systems OK" if all_ok else "One or more endpoints failed"