#!/bin/bash

# === ASK FOR REGION ===
read -p "Enter your Dataproc region (e.g., us-central1): " REGION
CLUSTER_NAME="example-cluster"

echo "[1/6] Setting Dataproc region to $REGION ..."
gcloud config set dataproc/region $REGION

echo "[2/6] Fetching Project ID and Number..."
PROJECT_ID=$(gcloud config get-value project)
gcloud config set project $PROJECT_ID
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')

echo "[3/6] Adding Storage Admin role to Compute Engine default service account..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
  --role=roles/storage.admin

echo "[4/6] Enabling Private Google Access on default subnet..."
gcloud compute networks subnets update default --region=$REGION --enable-private-ip-google-access

echo "[5/6] Creating Dataproc cluster: $CLUSTER_NAME..."
gcloud dataproc clusters create $CLUSTER_NAME \
  --worker-boot-disk-size=500 \
  --worker-machine-type=e2-standard-4 \
  --master-machine-type=e2-standard-4 \
  --region=$REGION \
  --quiet

echo "[6/6] Submitting Spark job to calculate Pi..."
gcloud dataproc jobs submit spark \
  --cluster=$CLUSTER_NAME \
  --class=org.apache.spark.examples.SparkPi \
  --jars=file:///usr/lib/spark/examples/jars/spark-examples.jar \
  -- 1000

echo "=== Dataproc setup and job submission completed! ==="
