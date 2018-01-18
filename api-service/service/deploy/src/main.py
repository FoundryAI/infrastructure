from ecs import DeployAction, EcsClient, TaskPlacementError, EcsError

import json
import boto3
import zipfile
import io
import traceback
from time import sleep
from datetime import datetime, timedelta

code_pipeline = boto3.client('codepipeline')
s3 = boto3.resource('s3')


def deploy_handler(event, context):
    """Notify Slack of CodePipeline event
    Args:
      event: The CodePipeline JSON payload
      context: lambda execution context
    """
    print(event)
    jobId = event['CodePipeline.job']['id']

    # Get userparameters string and decode as json
    user_parameters = event['CodePipeline.job']['data']['actionConfiguration']['configuration']['UserParameters']

    # decoded_parameters = json.loads(user_parameters, object_hook=ascii_encode_dict)
    payload = json.loads(user_parameters)
    print(payload)

    name = payload['task']
    tag = get_tag(event)

    env = [[name, 'Tag', tag]]
    image = [[name, u'%s:%s' % (payload['image'], tag.strip())]]

    try:
        deploy(
            cluster=payload['cluster'],
            task=name,
            service=payload['service'],
            tag=tag,
            env=env,
            image=image,
            role=payload['role'],
            region=payload['region'],
            access_key_id=payload['aws_access_key_id'],
            secret_access_key=payload['aws_secret_key'],
            rollback=True,
            timeout=300
        )
        code_pipeline.put_job_success_result(jobId=jobId)
    except Exception as e:
        print(e)
        traceback.print_exc(e)
        code_pipeline.put_job_failure_result(
            jobId=jobId,
            failureDetails={
                'type': 'JobFailed',
                'message': e.message
            }
        )


def get_tag(event):
    build_output = event['CodePipeline.job']['data']['inputArtifacts'][0]
    s3_loc = build_output['location']['s3Location']
    obj = s3.Object(s3_loc['bucketName'], s3_loc['objectKey']).get()

    with io.BytesIO(obj["Body"].read()) as tf:
        # rewind the file
        tf.seek(0)

        # Read the file as a zipfile
        with zipfile.ZipFile(tf, mode='r') as zipf:
            file_text = zipf.read('build.json')
            return json.loads(file_text)['tag']


# The following lines are adapted from cli.py of ecs-deploy
# https://github.com/fabfuel/ecs-deploy

def get_client(access_key_id, secret_access_key, region, profile):
    return EcsClient(access_key_id, secret_access_key, region, profile)


def get_task_definition(action, task):
    if task:
        task_definition = action.get_task_definition(task)
    else:
        task_definition = action.get_current_task_definition(action.service)
        task = task_definition.family_revision

    print('Deploying based on task definition: %s\n' % task)

    return task_definition


def print_diff(task_definition, title='Updating task definition'):
    if task_definition.diff:
        print(title)
        for diff in task_definition.diff:
            print(str(diff))
        print('')


def create_task_definition(action, task_definition):
    print('Creating new task definition revision')
    new_td = action.update_task_definition(task_definition)
    print('Successfully created revision: %d\n' % new_td.revision)
    return new_td


def deregister_task_definition(action, task_definition):
    print('Deregister task definition revision')
    action.deregister_task_definition(task_definition)
    print('Successfully deregistered revision: %d\n' % task_definition.revision)


def rollback_task_definition(deployment, old, new, timeout=600):
    print (
        'Rolling back to task definition: %s\n' % old.family_revision
    )
    deploy_task_definition(
        deployment=deployment,
        task_definition=old,
        title='Deploying previous task definition',
        success_message='Rollback successful',
        failure_message='Rollback failed. Please check ECS Console',
        timeout=timeout,
        deregister=True,
        previous_task_definition=new,
        ignore_warnings=False
    )
    print(
        'Deployment failed, but service has been rolled back to previous '
        'task definition: %s\n' % old.family_revision
    )


def deploy_task_definition(deployment, task_definition, title, success_message,
                           failure_message, timeout, deregister,
                           previous_task_definition, ignore_warnings):
    print('Updating service')
    deployment.deploy(task_definition)

    message = 'Successfully changed task definition to: %s:%s\n' % (
        task_definition.family,
        task_definition.revision
    )

    print(message)

    wait_for_finish(
        action=deployment,
        timeout=timeout,
        title=title,
        success_message=success_message,
        failure_message=failure_message,
        ignore_warnings=ignore_warnings
    )

    if deregister:
        deregister_task_definition(deployment, previous_task_definition)


def deploy(cluster, service, tag, role, task, region, access_key_id, secret_access_key, ignore_warnings=False,
           timeout=300, image=[], command=[], env=[], profile=None, diff=True, deregister=True, rollback=False):
    """
    Redeploy or modify a service.

    \b
    CLUSTER is the name of your cluster (e.g. 'my-custer') within ECS.
    SERVICE is the name of your service (e.g. 'my-app') within ECS.

    When not giving any other options, the task definition will not be changed.
    It will just be duplicated, so that all container images will be pulled
    and redeployed.
    """

    try:
        client = get_client(access_key_id, secret_access_key, region, profile)
        deployment = DeployAction(client, cluster, service)

        td = get_task_definition(deployment, task)
        td.set_images(tag, **{key: value for (key, value) in image})
        td.set_commands(**{key: value for (key, value) in command})
        td.set_environment(env)
        td.set_role_arn(role)

        if diff:
            print_diff(td)

        new_td = create_task_definition(deployment, td)

        try:
            deploy_task_definition(
                deployment=deployment,
                task_definition=new_td,
                title='Deploying new task definition',
                success_message='Deployment successful',
                failure_message='Deployment failed',
                timeout=timeout,
                deregister=deregister,
                previous_task_definition=td,
                ignore_warnings=ignore_warnings,
            )

        except TaskPlacementError as e:
            if rollback:
                print('%s\n' % str(e))
                rollback_task_definition(deployment, td, new_td)
                # exit(1)
                raise
            else:
                raise

    except (EcsError) as e:
        print('%s\n' % str(e))
        raise
        # exit(1)


def wait_for_finish(action, timeout, title, success_message, failure_message,
                    ignore_warnings):
    print(title)
    waiting = True
    waiting_timeout = datetime.now() + timedelta(seconds=timeout)
    service = action.get_service()
    inspected_until = None
    while waiting and datetime.now() < waiting_timeout:
        print('.')
        service = action.get_service()
        inspected_until = inspect_errors(
            service=service,
            failure_message=failure_message,
            ignore_warnings=ignore_warnings,
            since=inspected_until,
            timeout=False
        )
        waiting = not action.is_deployed(service)

        if waiting:
            sleep(1)

    inspect_errors(
        service=service,
        failure_message=failure_message,
        ignore_warnings=ignore_warnings,
        since=inspected_until,
        timeout=waiting
    )

    print('\n%s\n' % success_message)

def inspect_errors(service, failure_message, ignore_warnings, since, timeout):
    error = False
    last_error_timestamp = since

    warnings = service.get_warnings(since)
    for timestamp in warnings:
        message = warnings[timestamp]
        print('')
        if ignore_warnings:
            last_error_timestamp = timestamp
            print('%s\nWARNING: %s' % (timestamp, message))
            print('Continuing.')
        else:
            print('%s\nERROR: %s\n' % (timestamp, message))
            error = True

    if service.older_errors:
        print('')
        print('Older errors')
        for timestamp in service.older_errors:
            print('%s\n%s\n' % (timestamp, service.older_errors[timestamp]))

    if timeout:
        error = True
        failure_message += ' due to timeout. Please see: ' \
                           'https://github.com/fabfuel/ecs_deploy#timeout'
        print('')

    if error:
        raise TaskPlacementError(failure_message)

    return last_error_timestamp

