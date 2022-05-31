# chainsaw: demo

```
trash -rf ~/.mandelbot ~/.ignite/local-chains/mandelbot

cd ~/dev/oktryme

./chainsaw/chainsaw.sh johnreitano mandelbot

cd mandelbot
code .

terraform -chdir=deploy apply
```
