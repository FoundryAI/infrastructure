variable event_target_arn {
  description = "ARN of the target"
}

variable task_count {
  description = "Number of tasks"
  default = 1
}

variable task_definition_arn {
  description = "ARN of the task to invoke"
}

variable event_rule_name {
  description = "Name of the event rule"
  default = ""
}

variable event_rule_description {
  description = "Description of event rule"
  default = ""
}

variable event_rule_pattern {
  description = "Pattern for event rule"
}

variable "environment" {
}
