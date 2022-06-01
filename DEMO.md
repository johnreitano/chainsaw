# chainsaw: demo script

Run the following commands, one line at a time
```
cd ~/dev/oktryme

./chainsaw/chainsaw.sh johnreitano mandelbot

code mandelbot

terraform -chdir=deploy apply

terraform -chdir=deploy destroy

trash -rf ~/.mandelbot ~/.ignite/local-chains/mandelbot
```
