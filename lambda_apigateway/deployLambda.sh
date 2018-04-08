#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#set -o nounset -o errexit -o pipefail
set -o nounset

lambdaRole="myLambdaRole"
bucketName="chinese-poetry"
region="ap-northeast-1"
timeout=60
memory=3008
runtime="python3.6"
bucketName="chinese-poetry"
s3key="pack.zip"
functionName="chinesePoetry"
handler="compose.lambda_handler"
modelFile="model/chinese_poetry_model.tgz"


echo "Create role for lambda function ..."
aws iam create-role \
        --role-name ${lambdaRole} \
        --assume-role-policy-document file://${lambdaRole}.json

#echo "Put policy on the role of ${lambdaRole}"
#aws iam put-role-policy \
#	--role-name ${lambdaRole} \
#	--policy-name ${lambdaRole}-policy \
#	--policy-document file://${lambdaRole}.json 

policyArns=(
	"arn:aws:iam::aws:policy/AWSLambdaExecute" 
	"arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
)

for policyArn in "${policyArns[@]}"
do
	aws iam attach-role-policy \
		--role-name  ${lambdaRole} \
		--policy-arn ${policyArn}
	echo "Policy ${policyArn} has been attached"
done

#echo "Attach policy to the role ..."
#aws iam attach-role-policy \
#        --role-name  ${lambdaRole} \
#        --policy-arn arn:aws:iam::aws:policy/AWSLambdaExecute

#aws iam attach-role-policy \
#        --role-name  ${lambdaRole} \
#        --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess

#echo "Create S3 bucket ..."
aws s3 --region "${region}" mb s3://${bucketName}

echo "Copy package/model pack to S3 bucket ..."
aws s3 cp ${s3key} s3://${bucketName}/  
aws s3 cp ${modelFile} s3://${bucketName}/

echo "Waiting 10 seconds to replicate your new role through all regions."
sleep 10

echo "Get the role ARN"
roleArn=$(aws iam get-role --role-name ${lambdaRole} --output text --query "Role.{Id:Arn}")
echo "role's ARN is $roleArn"

echo "Create lambda function ..."
aws lambda create-function \
	--function-name ${functionName} \
	--runtime ${runtime} \
	--handler ${handler} \
	--region ${region} \
	--code S3Bucket=${bucketName},S3Key=${s3key} \
	--role ${roleArn} \
	--timeout ${timeout} \
	--memory-size ${memory}

echo "Test lambda function ..."
start=$(date +%s)
aws --region ${region} lambda invoke --function-name ${functionName} --invocation-type RequestResponse output.json
end=$(date +%s)
runtime=$((end-start))
echo "Running time is ${runtime} second(s)"

if [ -f "output.json" ]; then
	echo "$(<output.json)"
fi
