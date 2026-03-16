
set -a
source "$(dirname "$0")/.env.ec2"
set +a

#terraform plan
terraform init
terraform apply
