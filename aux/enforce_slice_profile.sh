#!/bin/bash

API_URL="http://10.16.10.74:8000"
# Check if profile is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <profile>"
  exit 1
fi

# Set the profile variable
profile=$1

# Execute the curl command with the profile variable
curl --location --request PATCH "${API_URL}/productOrder/${profile}/patch" \
--header "Content-Type: application/json" \
--data '{
    "administrative_state": "UNLOCKED",
    "operational_state": "ENABLED"
}'