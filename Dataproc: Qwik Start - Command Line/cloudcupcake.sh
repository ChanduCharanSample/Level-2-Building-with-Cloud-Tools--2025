#!/bin/bash

# === Detect Project ===
PROJECT_ID=$(gcloud config get-value project)
gcloud config set project $PROJECT_ID
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')

# === Detect or Ask for Region ===
DEFAULT_REGION=$(gcloud compute networks subnets list --filter="default" --format="value(region)" | head -n 1)
read -p "Enter Dataproc region (default: $DEFAULT_REGION): " REGION
REGION=${REGION:-$DEFAULT_REGION}
gcloud config set dataproc/region $REGION

echo "Using Project: $PROJECT_ID"
echo "Using Region: $REGION"

# === Grant IAM Roles ===
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
  --role=roles/storage.admin

# === Enable Private Google Access ===
gcloud compute networks subnets update default --region=$REGION --enable-private-ip-google-access

# === Check if Cluster Exists ===
if gcloud dataproc clusters describe example-cluster --region=$REGION &>/dev/null; then
    echo "Cluster 'example-cluster' already exists. Skipping creation..."
else
    echo "Creating Dataproc cluster..."
    gcloud dataproc clusters create example-cluster \
      --worker-boot-disk-size=500 \
      --worker-machine-type=e2-standard-4 \
      --master-machine-type=e2-standard-4 \
      --image-version=2.0-debian10 \
      --region=$REGION
fi

# === Wait for Cluster to be Ready ===
echo "Waiting for cluster to be ready..."
gcloud dataproc clusters wait example-cluster --region=$REGION

# === Submit SparkPi Job ===
echo "Submitting SparkPi job..."
gcloud dataproc jobs submit spark --cluster example-cluster \
  --class org.apache.spark.examples.SparkPi \
  --jars file:///usr/lib/spark/examples/jars/spark-examples.jar -- 1000

echo "Job submitted successfully!"
