autostop-ec2 Terraform module
===================================

A Terraform module to manage stopping or starting EC2 Instances.

This module creates Lambda functions, cloudwatch events, permissions and IAM role to stopping or starting EC2 Instance at a scheduled time selected by filters.

Module Input Variables
----------------------

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| enabled\_start |  | string | `"true"` | no |
| enabled\_stop |  | string | `"true"` | no |
| filters\_start |  | string | `"[{'Name': 'tag:autoOff','Values':['True']},{'Name':'instance-state-name','Values':['stopped']}]"` | no |
| filters\_stop |  | string | `"[{'Name': 'tag:autoOff','Values':['True']},{'Name':'instance-state-name','Values':['running']}]"` | no |
| memory\_size |  | string | `"128"` | no |
| name |  | string | n/a | yes |
| schedule\_start |  | string | `"cron(0 7 ? * MON-FRI *)"` | no |
| schedule\_stop |  | string | `"cron(0 19 ? * MON-FRI *)"` | no |
| tags | Additional tags (e.g. map(`Env`,`dev`) | map | `<map>` | no |
| timeout |  | string | `"3"` | no |

Usage
-----

```
module "autostop-preprod" {
  source = "./autostop-ec2/"
  name   = "eco-preprod"
}
```

Authors
=======

Originally created and maintained by:
 * [Christophe Gasmi](https://github.com/rekcah78)

