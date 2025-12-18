# kb-s3-vectors-tf

ブログ: https://dev.classmethod.jp/articles/terraform-aws-s3-vectors-bedrock-rag/

## 構成

```bash
.
├── README.md
└── terraform
    ├── main.tf
    ├── outputs.tf
    ├── providers.tf
    ├── terraform.tfstate
    ├── terraform.tfvars
    ├── terraform.tfvars.example
    └── variables.tf
```

## 使い方

```bash
cd terraform
terraform init
terraform plan
terraform apply
```