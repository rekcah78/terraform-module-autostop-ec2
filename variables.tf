variable "name" {}

variable "tags" {
  type        = "map"
  default     = {}
  description = "Additional tags (e.g. map(`Env`,`dev`)"
}

variable "enabled_start" {
  default = true
}

variable "enabled_stop" {
  default = true
}

variable "timeout" {
  default = "3"
}

variable "memory_size" {
  default = "128"
}

variable "schedule_start" {
  default = "cron(0 7 ? * MON-FRI *)"
}

variable "schedule_stop" {
  default = "cron(0 19 ? * MON-FRI *)"
}

variable "filters_start" {
  default = "[{'Name': 'tag:autoOff','Values':['True']},{'Name':'instance-state-name','Values':['stopped']}]"
}

variable "filters_stop" {
  default = "[{'Name': 'tag:autoOff','Values':['True']},{'Name':'instance-state-name','Values':['running']}]"
}

# Locals
locals {
  stack_tags = {
    Component = "lambda"
    Module    = "autostop-ec2"
  }

  tags = "${merge(var.tags, local.stack_tags)}"
}