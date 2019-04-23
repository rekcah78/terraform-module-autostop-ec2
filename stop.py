import boto3
import logging
import os
import json

logger = logging.getLogger()
logger.setLevel(logging.INFO)

ec2 = boto3.client('ec2')
ASG_TAG = 'aws:autoscaling:groupName'

def stop(event, context):
    if os.environ['FILTERS'] == "":
        exit(1)
    filters = os.environ['FILTERS']
    FILTERS =  json.loads(filters.replace("'",'"'))
    instance_desc = ec2.describe_instances(Filters=FILTERS)
    RunningInstances = list()
    for reservation in instance_desc['Reservations']:
        for instance in reservation['Instances']:
            instance_id = instance['InstanceId']
            instance_tags = map(lambda x: x['Key'].lower(), instance['Tags'])
            is_spot_instance = True if instance.get('InstanceLifecycle', '') == 'spot' else False
            if ASG_TAG.lower() in instance_tags:
                print('INFO: instance %s is part of an Auto Scaling Group . Skipping' % instance_id)
                continue
            if is_spot_instance:
                print('INFO: instance %s is type Spot . Skipping' % instance_id)
                continue
            RunningInstances.append(instance_id)
    print "Running Instance are : ", RunningInstances
    if len(RunningInstances) > 0:
        stoppedInstances = ec2.stop_instances(InstanceIds=RunningInstances)
        print "Stopping: ", stoppedInstances
    else:
        print "Nothing to do, every instances are already down ?"
    return 0
