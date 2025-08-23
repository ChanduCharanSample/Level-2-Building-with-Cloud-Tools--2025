#!/bin/bash

# === Detect Project ID ===
PROJECT_ID=$(gcloud config get-value project)
gcloud config set project $PROJECT_ID
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')

# === Ask for Region ===
read -p "Enter Dataproc region (default: us-east1): " REGION
REGION=${REGION:-us-east1}
gcloud config set dataproc/region $REGION

# === Grant Storage Admin Role to Compute Engine Default Service Account ===
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
  --role=roles/storage.admin

# === Enable Private Google Access ===
gcloud compute networks subnets update default --region=$REGION --enable-private-ip-google-access

# === Create Dataproc Cluster ===
gcloud dataproc clusters create example-cluster \
  --worker-boot-disk-size 500 \
  --worker-machine-type=e2-standard-4 \
  --master-machine-type=e2-standard-4 \
  --region=$REGION

# === Submit SparkPi Job ===
gcloud dataproc jobs submit spark --cluster example-cluster \
  --class org.apache.spark.examples.SparkPi \
  --jars file:///usr/lib/spark/examples/jars/spark-examples.jar -- 1000
