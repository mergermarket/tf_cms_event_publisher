variable "env" {
  description = "Environment name"
}

variable "events_table" {
  description = "The name of the DynamoDB table used to store events"
  type        = "string"
}

variable "snapshots_table" {
  description = "The name of the DynamoDB table used to store snapshots"
  type        = "string"
}

variable "cms_name" {
  description = "The name of the CMS creating the infrastructure"
  type        = "string"
}
