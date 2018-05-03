output "events_table_arn" {
  value       = "${aws_dynamodb_table.events.arn}"
  description = "ARN for the DynamoDB events table."
}

output "snapshots_table_arn" {
  value       = "${aws_dynamodb_table.snapshots.arn}"
  description = "ARN for the DynamoDB snapshots table."
}

output "created_events_table" {
  value       = "${aws_dynamodb_table.events.id}"
  description = "Name of the created DynamoDB events table."
}

output "created_snapshots_table" {
  value       = "${aws_dynamodb_table.snapshots.id}"
  description = "Name of the created DynamoDB snapshots table."
}

output "events_topic_arn" {
  value       = "${aws_sns_topic.sns_topic.arn}"
  description = "ARN for the events SNS topic."
}
