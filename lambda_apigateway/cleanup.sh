#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#set -o nounset -o errexit -o pipefail
set -o nounset

myLambdaRole="myLambdaRole"
bucketName="chinese-poetry"
region="ap-northeast-1"
bucketName="chinese-poetry"
functionName="chinesePoetry"

#Delete S3 bucket
echo "Delete S3 bucket"
aws s3 rm s3://${bucketName} --recursive
aws s3 rb s3://${bucketName} --force  


echo "Detach policies on the role of ${myLambdaRole}"
#Detach policy of AWSLambdaExecute
aws iam detach-role-policy --role-name ${myLambdaRole} --policy-arn arn:aws:iam::aws:policy/AWSLambdaExecute

#Detach policy of AmazonS3ReadOnlyAccess
aws iam detach-role-policy --role-name ${myLambdaRole} --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess

echo "delete role of ${myLambdaRole}"
aws iam delete-role --role-name ${myLambdaRole}

echo "Removing the permissions from the lambda"
aws --region ${region} lambda remove-permission \
  --function-name ${functionName} \
  --statement-id apigateway-${functionName}-get

aws --region ${region} lambda remove-permission \
  --function-name ${functionName} \
  --statement-id apigateway-${functionName}-get-start


echo "Delete Lambda function ${functionName}"
aws --region ${region} lambda delete-function --function-name ${functionName} 


echo "Reading API ID when create api"
apiID=$(<apiID.txt)
echo "API ID is $apiID"

echo "Deleting the API"
aws --region ${region} apigateway delete-rest-api \
  --rest-api-id "${apiID}"

echo "Done."
