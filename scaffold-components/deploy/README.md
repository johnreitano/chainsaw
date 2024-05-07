# Deploying a testnet

## Step 1: Install dependencies

```
brew install jq terraform awscli
```

## Step 2: Set up name servers

From the project root dir:

```
deploy/create-zone.sh testnet yourchain.yourdomain.com youremail@example.com
```

This command will output a list of name servers. At the host for the subdomain (eg, `yourchain.yourdomain.com`), add one NS record for each name server in the output. Wait for the NS records to be propagated (this can take anywhere from 15 minutes to 8 hours). You can confirm the name server records are propagated by running the command 
```
nslookup -type=ns testnet.yourchain.yourdomain.com
```
At first you will see a failure message such as `** server can't find testnet.yourchain.yourdomain.com: NXDOMAIN`. If you see a response similar to the following, then the name servers are propagated:
```
Server:         10.136.126.106
Address:        10.136.126.106#53

Non-authoritative answer:
testnet.yourchain.yourdomain.com    nameserver = ns-1306.awsdns-35.org.
testnet.yourchain.yourdomain.com    nameserver = ns-143.awsdns-17.com.
testnet.yourchain.yourdomain.com    nameserver = ns-800.awsdns-36.net.
testnet.yourchain.yourdomain.com    nameserver = ns-1694.awsdns-19.co.uk.

Authoritative answers can be found from:
ns-143.awsdns-17.com    internet address = 205.251.192.143
ns-800.awsdns-36.net    internet address = 205.251.195.32
ns-1306.awsdns-35.org   internet address = 205.251.197.26
ns-1694.awsdns-19.co.uk internet address = 205.251.198.158
ns-143.awsdns-17.com    has AAAA address 2600:9000:5300:8f00::1
ns-800.awsdns-36.net    has AAAA address 2600:9000:5303:2000::1
ns-1306.awsdns-35.org   has AAAA address 2600:9000:5305:1a00::1
```

## Step 3: Deploy your chain

From the project root dir:

```
deploy/create-servers.sh testnet yourchain.yourdomain.com youremail@example.com
```

#### Step 4: Behold your testnet

Wait 2-3 minutes, the visit your new api:

```
open https://validator-0-api.yourchain.yourdomain.com
```

See your servers in AWS:

```
open https://us-west-2.console.aws.amazon.com/ec2/v2/home?region=us-west-2#Instances:
```

See your ip addresses:

```
terraform -chdir=deploy output
# => seed_ips = [
#   "44.228.170.68",
# ]
# validator_ips = [
#   "35.165.126.194",
#   "52.43.111.204",
#   "54.200.98.222",
#]
```

Use some nifty commands in your scripts:

```
deploy/show-ip.sh seed 0
# => 44.228.170.68
deploy/show-ip.sh validator 0
# => 35.165.126.194
deploy/show-api.sh validator 0
# => http://35.165.126.194:1317
deploy/ssh.sh validator 0
# => ubuntu@ip-10-0-2-45:~$
deploy/ssh validator 0 date
# => Tue May 31 02:23:06 UTC 2022
```

## Destroying your testnet (to save money!)

From your project root dir:

```
deploy/destroy-servers.sh testnet
```

## Destroying your zone and any remaining servers

There may be a small monthly charge from some AWS resources such as hosting your dns zone or other items. To remove all of these resources, cd to project root dir and run:

```
deploy/destroy-all.sh testnet
```
