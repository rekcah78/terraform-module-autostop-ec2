import boto3
import logging
import os
import json

logger = logging.getLogger()
logger.setLevel(logging.INFO)

ec2 = boto3.resource('ec2')

def start(event, context):
    if os.environ['FILTERS'] == "":
        exit(1)
    filters = os.environ['FILTERS']
    FILTERS =  json.loads(filters.replace("'",'"'))
    instances = ec2.instances.filter(Filters=FILTERS)
    stoppedInstances = [instance.id for instance in instances]
    print "Stopped Instance are : ", stoppedInstances
    if len(stoppedInstances) > 0:
        runningInstances = ec2.instances.filter(InstanceIds=stoppedInstances).start()
        print "Starting: ", runningInstances
    else:
        print "Nothing to do, every instances are already up ?"
    return 0
