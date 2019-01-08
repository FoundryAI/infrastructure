variable event_target_arn {
  description = ""
}

variable target_input {
  description = ""
}

variable task_count {
  description = "Number of tasks"
  default = 1
}

variable task_definition_arn {
  description = ""
}

variable event_rule_name {
  description = ""
  default = ""
}

variable event_rule_description {
  description = "Description of event rule"
  default = ""
}

variable event_rule_pattern {
  description = "Pattern for event rule"
}
