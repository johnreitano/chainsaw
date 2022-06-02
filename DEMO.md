# chainsaw: demo script

Run the following commands, one line at a time

```
cd ~/dev/oktryme

./chainsaw/chainsaw.sh johnreitano newchain

code newchain

terraform -chdir=deploy apply

terraform -chdir=deploy destroy

trash -rf ~/.newchain ~/.ignite/local-chains/newchain
```
