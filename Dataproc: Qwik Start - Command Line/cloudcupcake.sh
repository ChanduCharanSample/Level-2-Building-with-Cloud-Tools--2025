#!/bin/bash
# Automate Dataproc Cluster Creation & Job Submission

# Detect Project ID & Project Number
PROJECT_ID=$(gcloud config get-value project)
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')

# Default Region
REGION="us-west1"

# Set Dataproc Region
gcloud config set dataproc/region $REGION
gcloud config set project $PROJECT_ID

# Grant Storage Admin Role to Compute Engine default service account
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
  --role="roles/storage.admin"

# Enable Private Google Access
gcloud compute networks subnets update default --region="$REGION" --enable-private-ip-google-access

# Create Dataproc Cluster
gcloud dataproc clusters create example-cluster \
  --worker-boot-disk-size 500 \
  --worker-machine-type=e2-standard-4 \
  --master-machine-type=e2-standard-4 \
  --region="$REGION" --quiet

# Submit Spark Job
gcloud dataproc jobs submit spark --cluster=example-cluster \
  --class=org.apache.spark.examples.SparkPi \
  --jars=file:///usr/lib/spark/examples/jars/spark-examples.jar -- 1000 \
  --region="$REGION"

echo "Dataproc Cluster created and SparkPi job submitted successfully!"
