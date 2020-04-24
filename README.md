# terraform-alternator-lb

### Getting started

```bash
export CLUSTER_ID=2702
```

```
./scylla-cloud cluster describe --cluster-id $CLUSTER_ID --format yaml > cluster.yaml
```

```
aws-vault add lab
```

```
aws-vault exec lab -- terraform init
aws-vault exec lab -- terraform apply -auto-approve
```
