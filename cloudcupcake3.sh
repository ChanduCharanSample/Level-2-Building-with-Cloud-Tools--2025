#!/bin/bash
# ===================================================
# Google Cloud Document AI Lab - Automated Script
# ===================================================

set -e

# --- Variables ---
PROJECT_ID=$(gcloud config get-value core/project)
REGION="us"
LOCATION="us"
WORK_DIR=$HOME/docai_lab
mkdir -p $WORK_DIR
cd $WORK_DIR

echo "Using Project: $PROJECT_ID"

# --- 1. Enable APIs ---
echo "Enabling Document AI API..."
gcloud services enable documentai.googleapis.com

# --- 2. Create Form Parser Processor ---
echo "Creating Form Parser processor..."
FORM_PARSER=$(gcloud documentai processors create \
  --display-name="form-parser" \
  --type=form-parser \
  --region=$REGION \
  --format="value(name)")
FORM_PARSER_ID=$(echo $FORM_PARSER | awk -F/ '{print $6}')
echo "Form Parser Processor ID: $FORM_PARSER_ID"

# --- 3. Create OCR Processor ---
echo "Creating OCR processor..."
OCR_PARSER=$(gcloud documentai processors create \
  --display-name="ocr-processor" \
  --type=ocr-parser \
  --region=$REGION \
  --format="value(name)")
OCR_PARSER_ID=$(echo $OCR_PARSER | awk -F/ '{print $6}')
echo "OCR Processor ID: $OCR_PARSER_ID"

# --- 4. Setup Vertex AI Workbench (if not already created) ---
# NOTE: Labs usually provision Workbench, but you can create one
# gcloud notebooks instances create document-ai-lab --vm-image-project=deeplearning-platform-release --vm-image-family=tf2-latest-cpu --machine-type=n1-standard-4 --location=$REGION

# --- 5. Install Python Dependencies ---
echo "Installing Python dependencies..."
python3 -m pip install --upgrade google-cloud-core google-cloud-documentai google-cloud-storage prettytable

# --- 6. Prepare Cloud Storage for Async Processing ---
echo "Creating Cloud Storage bucket..."
BUCKET="${PROJECT_ID}_doc_ai_async"
gsutil mb -l $REGION gs://${BUCKET} || echo "Bucket already exists"
# Upload example forms (replace with real path)
# gsutil -m cp /path/to/forms/*.pdf gs://${BUCKET}/input

# --- 7. Generate Python Script for Sync & Async Processing ---
cat > process_docai.py <<EOF
from google.cloud import documentai_v1 as documentai
from google.cloud import storage
from prettytable import PrettyTable
import os

project_id = "$PROJECT_ID"
location = "$LOCATION"
form_parser_id = "$FORM_PARSER_ID"
ocr_parser_id = "$OCR_PARSER_ID"

def process_sync(processor_id, file_path="form.pdf"):
    client = documentai.DocumentProcessorServiceClient()
    name = f"projects/{project_id}/locations/{location}/processors/{processor_id}"
    with open(file_path, "rb") as f:
        image_content = f.read()
    document = {"content": image_content, "mime_type": "application/pdf"}
    request = {"name": name, "document": document}
    result = client.process_document(request=request)
    print("Document processing complete.")
    print(result.document.text[:500])  # print first 500 chars
    return result.document

if __name__ == "__main__":
    # Run sync with form parser
    print("=== Running Sync Processing with Form Parser ===")
    process_sync(form_parser_id, "form.pdf")

    # Run sync with OCR parser
    print("=== Running Sync Processing with OCR Parser ===")
    process_sync(ocr_parser_id, "form.pdf")
EOF

echo "Python script written to process_docai.py"
echo "Run with: python3 process_docai.py"
