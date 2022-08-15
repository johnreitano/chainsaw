# chainsaw: generate a new cosmos-sdk-based blockchain and deploy it to a testnet on AWS

## Install dependencies

1. Install docker desktop: https://docs.docker.com/get-docker/

2. Install build tools: `brew install jq terraform awscli`

## Generate and deploy a chain

#### Step 1: Generate chain

```
cd parent-directory-of-my-new-chain
path/to/this/repo/chainsaw.sh my-github-org my-awesome-chain
cd my-awesome-chain
```

#### Step 2: Create hosted domain zone

1. Choose a subdomain under your domain name to act as the root of the urls for your new blockchain. Example: If you own foo.com, you could choose "my-awesome-chain.foo.com".

2. Create a DNS zone for this full domain by running the create-zone.sh command: from the project root dir, run:

```
deploy/create-zone.sh my-awesome-chain.foo.com
```

3. Visit the DNS manager for your domain (eg, foo.com), and create 4 NS records for your chosen subdomain, one for each of the name servers in the output of create-zone.sh above. NOTE: It could take 1-4 hours for these NS records to propate, which you can check with the following command:

```
nslookup -type=ns awesome-chain.foo.com
```

#### Step 3: Deploy testnet servers

From your project root dir:

```
deploy/create-servers.sh 3 # number of desired validators
```

#### Step 4: Behold your testnet

See your new block explorer: https://testnet2-explorer.my-awesome-chain.foo.com

See your api: https://testnet2-seed-0-api.my-awesome-chain.foo.com

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

## Destroying everying (including your your DNS zone)

From your project root dir:

```
deploy/destroy-all.sh
```

## Possible Enhancements

- Deploy to a mainnet with anti-DDOS and other security-related features
- Support other cloud providers (Linode, Digital Ocean, etc.)
