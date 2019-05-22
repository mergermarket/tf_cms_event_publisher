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

variable "snapshots_read_capacity" {
  description = "The read capacity of the snapshots DynamoDB table"
  type        = "string"
  default     = "1"
}

variable "snapshots_write_capacity" {
  description = "The write capacity of the snapshots DynamoDB table"
  type        = "string"
  default     = "1"
}

variable "cms_name" {
  description = "The name of the CMS creating the infrastructure"
  type        = "string"
}
