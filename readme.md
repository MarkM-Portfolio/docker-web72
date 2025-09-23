# Installation
-  ##### Install AWS CLI v2 on your computer follow reference below:
> https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html

- ##### Install Amazon ECR credential helper
> https://github.com/awslabs/amazon-ecr-credential-helper
```
- alternative way is to run this command every 12 hours or before pull/push
aws ecr get-login-password | docker login --username AWS --password-stdin 138712986839.dkr.ecr.ap-southeast-1.amazonaws.com/web56:latest

so this command, will get login token from aws cli, then pass it to “docker login” to login. token is valid for 12 hours only.
it is kind of manual work, if you can configure the above plugin, it will be more convenient
```

- ##### Configure Amazon ECR Credential
```
On your local computer place the docker-credential-ecr-login binary on your PATH 
and set the contents of your ~/.docker/config.json file to be:

{
	"credsStore": "ecr-login"
}
```
> This configures the Docker daemon to use the credential helper for all Amazon ECR registries.

- ##### Amazon ECR Credential CLI configuration
```
aws configure

this will ask for the AWS Access Key ID?: IDXXXXXX
also for the AWS Secret Access key:? SECRETXXXXX
Default region name: ap-southeast-1
Default output format: just press enter
```

### How to run the docker image

- ##### Build the docker image
```
docker build -t web56 .
```

- ##### Run container and assign image as web56 and expose port 80   
```
docker run --detach --publish 80:80 --name web56 web56
```
> https://docs.docker.com/engine/reference/commandline/run/

- ##### Run image   
```
docker run --detach --publish 80:80 CONTAINER_NAME
```
> https://docs.docker.com/engine/reference/commandline/run/

- ##### Stop container
```
docker stop [OPTIONS] CONTAINER [CONTAINER...]
docker stop CONTAINER_NAME
```
> https://docs.docker.com/engine/reference/commandline/run/

- ##### Kill container   
```
docker kill [OPTIONS] CONTAINER [CONTAINER...]
docker kill web56
```
> https://docs.docker.com/engine/reference/commandline/run/

- ##### Login to the web56 container bash   
```
docker exec -it IMAGE_NAME bash
docker exec -it web56 bash
```

# Shortcut commands
- removes the previous container and runs the image web72 on port 80 detached mode as container web72
```
make start
```

- builds the image for the first time, runs the container under port 80 with container name web72
```
make init
```

- kills the container and re-issues the start command
```
make restart
```

- the build command with tag name web72
```
make build
```

- runs the image web72 on port 80, container name web72
```
make run
```

- removes the web72 container
```
make remove
```

- kills the web72 container process
```
make kill
```


