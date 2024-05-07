# chainsaw: generate a new cosmos-sdk-based blockchain and deploy it to a testnet on AWS

## Install dependencies

1. Install docker desktop: https://docs.docker.com/get-docker/

2. Install build tools: `brew install jq terraform awscli ignite`

3. Install the go version used by ignite (currently v1.22.2).
3. If not yet configured, configure aws: `aws configure` with credentials authorized to create AWS resources for EC2 and Route 53.

## Generate and deploy a chain

#### Step 1: Generate chain

Place `chainsaw.sh` in your PATH, and then run:
```
chainsaw.sh my-github-org my-awesome-chain
cd my-awesome-chain
```

#### Step 2: Create hosted domain zone

1. Choose a subdomain under your domain name to act as the root of the server urls for your new blockchain. Example: If you own foo.com, you could choose "my-awesome-chain.foo.com". Your servers will then given domains such as `valiator-0.testnet.my-awesome-chain.foo.com` or `valiator-0.mainnet.my-awesome-chain.foo.com`.

2. Create a DNS zone for this full domain by running the create-zone.sh command: from the project root dir, run:

```
deploy/create-zone.sh testnet my-awesome-chain.foo.com myemail@bigcorp.com
```

3. Visit the DNS manager for your domain (eg, foo.com), and create 4 NS records for your chosen subdomain, one for each of the name servers in the output of create-zone.sh above. NOTE: It could take 1-4 hours for these NS records to propate, which you can check with the following command:

```
nslookup -type=ns my-awesome-chain.foo.com
```

#### Step 3: Deploy testnet servers

From your project root dir:

```
deploy/create-servers.sh testnet 3 1 # number of desired validators and seeds
```

#### Step 4: Behold your testnet

See your new block explorer: https://explorer.testnet.my-awesome-chain.foo.com

See your api: https://seed-0-api.testnet.my-awesome-chain.foo.com

See your servers in AWS: https://us-west-2.console.aws.amazon.com/ec2/v2/home?region=us-west-2#Instances

See your ip addresses:

```
terraform -chdir=deploy output
# => seed_ips = [
# "44.228.170.68",
# ]
# validator_ips = [
# "35.165.126.194",
# "52.43.111.204",
# "54.200.98.222",
#]
```

Log into your servers:

```
deploy/ssh.sh validator 0
deploy/ssh.sh validator 1
deploy/ssh.sh seed 0
deploy/ssh.sh explorer 0
```

## Destroying your testnet servers (to save money!)

From your project root dir:

```
deploy/destroy-servers.sh
```

## Destroying everything (including your your DNS zone)

From your project root dir:

```
deploy/destroy-all.sh
```

## Possible Enhancements

- Deploy to a mainnet with anti-DDOS and other security-related features
- Support other cloud providers (Linode, Digital Ocean, etc.)


prep:

brew install awscli terraform
aws configure
terraform init
