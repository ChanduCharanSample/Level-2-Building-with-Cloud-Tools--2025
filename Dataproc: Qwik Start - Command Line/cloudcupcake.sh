#!/bin/bash

# Prompt for region
read -p "Enter the region for Dataproc (e.g., us-west1): " REGION

# Set Dataproc region
gcloud config set dataproc/region $REGION

# Disable and re-enable Dataproc API
gcloud services disable dataproc.googleapis.com --force
gcloud services enable dataproc.googleapis.com

# Get Project ID and Project Number
PROJECT_ID=$(gcloud config get-value project)
gcloud config set project $PROJECT_ID
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')

# Grant IAM roles to Compute Engine default service account
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/storage.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/dataproc.worker"

# Enable Private Google Access on default subnet
gcloud compute networks subnets update default --region=$REGION --enable-private-ip-google-access

# Create Dataproc cluster
gcloud dataproc clusters create example-cluster \
  --worker-boot-disk-size=500 \
  --worker-machine-type=e2-standard-4 \
  --master-machine-type=e2-standard-4

# Submit Spark job after cluster creation
echo "Submitting Spark job to calculate Pi..."
gcloud dataproc jobs submit spark --cluster example-cluster \
  --class org.apache.spark.examples.SparkPi \
  --jars file:///usr/lib/spark/examples/jars/spark-examples.jar -- 1000

echo "Job submitted successfully. Check output in Cloud Console or Cloud Shell logs."
