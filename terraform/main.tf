locals {
  name_prefix     = "${var.project_name}-${var.environment}"
  embedding_model = "amazon.titan-embed-text-v2:0"
  embedding_dim   = 1024
  distance_metric = "euclidean"
  data_type       = "float32"
}

data "aws_region" "current" {}
data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

# ------------------------------------------------------------------------------
# IAM Role for Bedrock Knowledge Base
# ------------------------------------------------------------------------------

data "aws_iam_policy_document" "kb_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["bedrock.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:bedrock:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:knowledge-base/*"]
    }
  }
}

data "aws_iam_policy_document" "kb_policy" {
  # Bedrock model invocation
  statement {
    effect = "Allow"
    actions = [
      "bedrock:InvokeModel"
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:bedrock:${data.aws_region.current.id}::foundation-model/${local.embedding_model}"
    ]
  }

  # S3 Vectors permissions
  statement {
    effect = "Allow"
    actions = [
      "s3vectors:GetIndex",
      "s3vectors:QueryVectors",
      "s3vectors:PutVectors",
      "s3vectors:GetVectors",
      "s3vectors:DeleteVectors"
    ]
    resources = [
      aws_s3vectors_index.main.index_arn
    ]
  }

  # S3 data source permissions
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.data_source.arn,
      "${aws_s3_bucket.data_source.arn}/*"
    ]
  }
}

resource "aws_iam_role" "kb" {
  name               = "${local.name_prefix}-kb-role"
  assume_role_policy = data.aws_iam_policy_document.kb_assume_role.json
}

resource "aws_iam_role_policy" "kb" {
  name   = "${local.name_prefix}-kb-policy"
  role   = aws_iam_role.kb.name
  policy = data.aws_iam_policy_document.kb_policy.json
}

# ------------------------------------------------------------------------------
# S3 Vectors - Vector Bucket and Index
# ------------------------------------------------------------------------------

resource "aws_s3vectors_vector_bucket" "main" {
  vector_bucket_name = "${local.name_prefix}-vectors"
  force_destroy      = true
}

resource "aws_s3vectors_index" "main" {
  index_name         = "${local.name_prefix}-index"
  vector_bucket_name = aws_s3vectors_vector_bucket.main.vector_bucket_name

  data_type       = local.data_type
  dimension       = local.embedding_dim
  distance_metric = local.distance_metric
  metadata_configuration {
    non_filterable_metadata_keys = [
      "AMAZON_BEDROCK_TEXT",
      "AMAZON_BEDROCK_METADATA",
      "x-amz-bedrock-kb-source-uri",
      "x-amz-bedrock-kb-chunk-id",
      "x-amz-bedrock-kb-data-source-id"
    ]
  }
}

# ------------------------------------------------------------------------------
# S3 Bucket for Data Source
# ------------------------------------------------------------------------------

resource "aws_s3_bucket" "data_source" {
  bucket        = "${local.name_prefix}-data-source-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "data_source" {
  bucket = aws_s3_bucket.data_source.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data_source" {
  bucket = aws_s3_bucket.data_source.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "data_source" {
  bucket                  = aws_s3_bucket.data_source.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ------------------------------------------------------------------------------
# Bedrock Knowledge Base
# ------------------------------------------------------------------------------

resource "aws_bedrockagent_knowledge_base" "main" {
  name     = "${local.name_prefix}-kb"
  role_arn = aws_iam_role.kb.arn

  knowledge_base_configuration {
    type = "VECTOR"
    vector_knowledge_base_configuration {
      embedding_model_arn = "arn:${data.aws_partition.current.partition}:bedrock:${data.aws_region.current.id}::foundation-model/${local.embedding_model}"
      embedding_model_configuration {
        bedrock_embedding_model_configuration {
          dimensions          = local.embedding_dim
          embedding_data_type = "FLOAT32"
        }
      }
    }
  }

  storage_configuration {
    type = "S3_VECTORS"
    s3_vectors_configuration {
      index_arn = aws_s3vectors_index.main.index_arn
    }
  }

  depends_on = [
    aws_iam_role_policy.kb
  ]
}

# ------------------------------------------------------------------------------
# Bedrock Data Source
# ------------------------------------------------------------------------------

resource "aws_bedrockagent_data_source" "main" {
  name              = "${local.name_prefix}-data-source"
  knowledge_base_id = aws_bedrockagent_knowledge_base.main.id

  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn = aws_s3_bucket.data_source.arn
    }
  }
}
