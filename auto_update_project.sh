#!/bin/bash
echo "#### Enter the version number (example: 1.0.0): ####"
read IMAGE_TAG

echo "Write Docker password:"
read -s -t 10 DOCKER_PASSWORD

docker-compose down
sleep 5

echo "### Restart the app with Docker-compose ####"


if grep -q "^[[:space:]]*my-app:" docker-compose.yaml; then
    export IMAGE_TAG
    awk '/^[[:space:]]*image:/ {sub(/:[^[:space:]]+/, ":" ENVIRON["IMAGE_TAG"])} { print }' docker-compose.yaml > docker-compose.tmp.yaml
    mv docker-compose.tmp.yaml docker-compose.yaml

    docker-compose up -d

    echo "#### Pushing image to Docker Hub ####"
    echo "$DOCKER_PASSWORD" | docker login -u ashot9632 --password-stdin
    docker push ashot9632/project_new:$IMAGE_TAG
    echo "#### Pushed version $IMAGE_TAG to Docker Hub ####"
else
    echo "WARNING! 'my-app' service not found in docker-compose.yaml"
    docker build -t ashot9632/project_new:$IMAGE_TAG .
    cd ~/Downloads/techworld-js-docker-demo-app-master/kube || exit 1
    docker-compose up -d
    docker run -d -p 3000:3000 ashot9632/project_new:$IMAGE_TAG
    echo "$DOCKER_PASSWORD" | docker login -u ashot9632 --password-stdin
    docker push ashot9632/project_new:$IMAGE_TAG
    echo "#### Pushed version $IMAGE_TAG to Docker Hub ####"
fi


echo "#### Pushing to AWS ECR ####"
aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin 800156316941.dkr.ecr.eu-central-1.amazonaws.com

docker build -t aws-private .
docker tag aws-private:latest 800156316941.dkr.ecr.eu-central-1.amazonaws.com/aws-private:$IMAGE_TAG
docker push 800156316941.dkr.ecr.eu-central-1.amazonaws.com/aws-private:$IMAGE_TAG

