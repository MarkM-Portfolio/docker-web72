start:
	make run success-message
init:
	make build run
restart:
	make kill start
build:
	./build.sh
run:
	./run.sh
remove:
	docker rm web72
kill:
	docker kill web72
success-message:
	echo running successfully
