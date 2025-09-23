docker rm web72 || true
docker run --publish 80:80 --name web72 web72:latest
