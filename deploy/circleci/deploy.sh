#!/bin/sh

export APP_VERSION=`git rev-parse --short HEAD`
export ARCHIVE_NAME="${APP_NAME}-${APP_VERSION}.zip"
echo "Deploying ${APP_NAME} ${APP_VERSION} to EB env ${ENV_NAME}"

echo "Clean build artifacts and create the application archive (also ignore any files named .git* in any folder)"
git clean -fd

echo "Delete old EB config if need be"
if ([ -d .ebextensions ]) then
  echo " -> Deleting old EB config"
  rm -rv .ebextensions
fi

echo "Copying ElasticBeanstalk config"
cp -r deploy/.ebextensions/ .ebextensions
cp "deploy/ebconfigs/${ENV_NAME}.yaml" ".ebextensions/02-${ENV_NAME}-env.config"

# precompile assets, ...

echo "Create zip archive of application to ${ARCHIVE_NAME}"
zip -x *.git* "node_modules/*" -r "${ARCHIVE_NAME}" .

echo "Delete any version with the same name (based on the short revision)"
aws elasticbeanstalk delete-application-version --application-name "${APP_NAME}" --version-label "${APP_VERSION}"  --delete-source-bundle

echo "Upload application to S3"
aws s3 cp "${ARCHIVE_NAME}" s3://${S3_BUCKET}/${APP_NAME}-${APP_VERSION}.zip

echo "Create a new version"
aws elasticbeanstalk create-application-version --application-name "${APP_NAME}" --version-label "${APP_VERSION}" --source-bundle S3Bucket="${S3_BUCKET}",S3Key="${APP_NAME}-${APP_VERSION}.zip"

echo "Update the environment to use this version"
aws elasticbeanstalk update-environment --environment-name "${ENV_NAME}" --version-label "${APP_VERSION}"
