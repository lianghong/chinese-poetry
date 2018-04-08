#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#set -o nounset -o errexit -o pipefail
set -o nounset

apiName="chinesePoetry"
functionName="chinesePoetry"
region="ap-northeast-1"
apiPathPart="compose"

echo "Get accountID for api invoking by HTTP protocol..."
if ! accountID=$(aws sts get-caller-identity --output text --query 'Account'); then
	echo "Failed get AWS account ID"
	exit 1
fi
echo "AWS User ID is ${accountID}"


echo "Creating a new API and capturing it's ID ..."
apiID=$(aws apigateway create-rest-api \
   --region ${region} \
   --name ${apiName} \
   --description "A Chinese poetry generation API" \
   --output text \
   --query 'id')
echo "API ID is: $apiID"

echo "Storing the API ID on file for cleanup  ..."
echo $apiID > apiID.txt

echo "Geting the root resource id for the API ..."
rootID=$(aws apigateway get-resources \
   --region ${region} \
   --rest-api-id "${apiID}" \
   --output text \
   --query 'items[?path==`'/'`].[id]')
echo "root ID is ${rootID}"

echo "Creating a resource for the /${apiPathPart} path"
resourceID=$(aws apigateway create-resource \
  --region ${region} \
  --rest-api-id "${apiID}" \
  --parent-id "${rootID}" \
  --path-part "${apiPathPart}" \
  --output text \
  --query "id") 
echo "Resource ID is $resourceID"

echo "Creating the GET method on the resource"
aws apigateway put-method \
  --region ${region} \
  --rest-api-id "${apiID}" \
  --resource-id "${resourceID}" \
  --http-method GET \
  --authorization-type "NONE" \
  --no-api-key-required \
  --request-parameters {}

echo "Get function's arn"
functionArn=$(aws --region ${region} lambda get-function --function-name ${functionName} --output text --query "Configuration.[FunctionArn]")
#echo "Function's arn is ${functionArn}"
functionUri="arn:aws:apigateway:${region}:lambda:path/2015-03-31/functions/${functionArn}/invocations"
#echo "Function's uri is ${functionUri}"

echo "Integrating the GET method to lambda"
aws apigateway put-integration \
  --region ${region} \
  --rest-api-id "${apiID}" \
  --resource-id "${resourceID}" \
  --http-method GET \
  --type AWS \
  --integration-http-method POST \
  --uri ${functionUri}  
  --request-templates '{"application/x-www-form-urlencoded":"{\"body\": $input.json(\"$\")}"}'

echo "Creating a default response for the GET method"
aws apigateway put-method-response \
  --region ${region} \
  --rest-api-id "${apiID}" \
  --resource-id "${resourceID}" \
  --http-method GET \
  --status-code 200 

echo "Creating a default response for the integration"
aws apigateway put-integration-response \
  --region ${region} \
  --rest-api-id "${apiID}" \
  --resource-id "${resourceID}" \
  --http-method GET \
  --status-code 200 \
  --selection-pattern ".*"

echo "Adding permission for the API to call the lambda for test, make the api call from console"
sourceArn="arn:aws:execute-api:${region}:${accountID}:${apiID}/*/GET/${apiPathPart}"
#echo "Source arn is ${sourceArn}"

aws lambda add-permission \
  --region ${region} \
  --function-name "${functionName}" \
  --statement-id "apigateway-${functionName}-get-start" \
  --action "lambda:InvokeFunction" \
  --principal "apigateway.amazonaws.com" \
  --source-arn "${sourceArn}"

echo "Adding permission for the API to call the lambda from any HTTP client"
aws lambda add-permission \
  --region ${region} \
  --function-name "${functionName}" \
  --statement-id "apigateway-${functionName}-get" \
  --action "lambda:InvokeFunction" \
  --principal "apigateway.amazonaws.com" \
  --source-arn "${sourceArn}"

echo "Creating a deployment"
aws apigateway create-deployment \
  --region ${region} \
  --rest-api-id "${apiID}" \
  --stage-name "api" 

echo "All done! you can invoke the api on https://${apiID}.execute-api.${region}.amazonaws.com/api/${apiPathPart}"
