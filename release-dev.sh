#bump the version
#docker run --rm -v "$PWD":/app treeder/bump patch
version=$(cat VERSION)
echo "version: $version"

# run build
./build-dev.sh

# Programmatically Git Tag
# git tag -a "$version" -m "version $version"
# git push
# git push --tags

# push it
docker tag dev-kumu-web72:latest $(aws sts get-caller-identity --query 'Account' --output text).dkr.ecr.ap-southeast-1.amazonaws.com/dev-kumu-web72:latest

docker push $(aws sts get-caller-identity --query 'Account' --output text).dkr.ecr.ap-southeast-1.amazonaws.com/dev-kumu-web72:latest

docker tag dev-kumu-web72:latest $(aws sts get-caller-identity --query 'Account' --output text).dkr.ecr.ap-southeast-1.amazonaws.com/dev-kumu-web72:$version

docker push $(aws sts get-caller-identity --query 'Account' --output text).dkr.ecr.ap-southeast-1.amazonaws.com/dev-kumu-web72:$version
