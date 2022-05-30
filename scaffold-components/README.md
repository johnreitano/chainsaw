# genchain: generate a new blockchain using the cosmos-sdk

### Manual script for demonstrations

```
trash -rf ~/.chainname ~/.ignite/local-chains/chainname

cd ~/dev/oktryme

ignite scaffold chain github.com/johnreitano/chainname --address-prefix chainname
cd chainname

cp -r ~/dev/oktryme/genchain/scaffold-components/* .

find . -type f -exec perl -i -pe"s/newchain/chainname/g" {} +

echo >>.gitignore <<-EOF
.terraform/
terraform.tfstate
terraform.tfstate.backup
terraform.tfvars
EOF

cd deploy
terraform init
(cd .. && git add .)
terraform apply -auto-approve
```
