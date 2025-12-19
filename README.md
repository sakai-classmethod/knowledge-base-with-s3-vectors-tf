# Knowledge Base with S3 Vectors (Terraform)

Amazon Bedrock Knowledge Base を S3 Vectors で構築する Terraform 構成。

## 構成

- S3 Vectors (ベクトルバケット + インデックス)
- Bedrock Knowledge Base
- S3 バケット (データソース用)
- IAM ロール

## 使用方法

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

## 変数

| 名前           | 説明           | デフォルト  |
| -------------- | -------------- | ----------- |
| `project_name` | プロジェクト名 | (必須)      |
| `aws_region`   | AWS リージョン | `us-east-1` |
| `environment`  | 環境名         | `dev`       |
