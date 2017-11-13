import sys
import os
import requests
import json

# def ascii_encode_dict(data):
#     ascii_encode = lambda x: x.encode('ascii')
#     return dict(map(ascii_encode, pair) for pair in data.items())


def send_post(event, context):
  """Notify Slack of CodePipeline event
  Args:
    event: The CloudWatch json input
    context: lambda execution context
  """
  print(event)

  webhook = os.environ['WEBHOOK']
  pipeline = event['detail']['pipeline']
  state = event['detail']['state']

  message = 'Pipeline {} has {}.'.format(pipeline, state)

  response = requests.post(webhook, headers={"Content-Type": "application/json"}, data=json.dumps({"text": message}))
  print response.text
  response.raise_for_status()


