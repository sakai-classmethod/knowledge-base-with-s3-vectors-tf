output "knowledge_base_id" {
  description = "ID of the Bedrock Knowledge Base"
  value       = aws_bedrockagent_knowledge_base.main.id
}

output "knowledge_base_arn" {
  description = "ARN of the Bedrock Knowledge Base"
  value       = aws_bedrockagent_knowledge_base.main.arn
}

output "vector_bucket_arn" {
  description = "ARN of the S3 Vectors bucket"
  value       = aws_s3vectors_vector_bucket.main.vector_bucket_arn
}

output "vector_index_arn" {
  description = "ARN of the S3 Vectors index"
  value       = aws_s3vectors_index.main.index_arn
}

output "data_source_bucket_name" {
  description = "Name of the S3 bucket for data source documents"
  value       = aws_s3_bucket.data_source.id
}

output "data_source_id" {
  description = "ID of the Bedrock Data Source"
  value       = aws_bedrockagent_data_source.main.data_source_id
}
