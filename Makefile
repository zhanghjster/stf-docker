.PHONY: build dev stop run dbdata clear_containers

centos = centos

dbdata:

	@echo prepare dbdata volume
	@if [ $(shell docker ps -a | grep -ci stf_mysqldata) -eq 0 ]; then \
		docker create -v /var/lib/mysql --name stf_mysqldata $(centos) /bin/true; \
	fi

	@echo prepare redisdata volume
	@if [ $(shell docker ps -a | grep -ci stf_redisdata) -eq 0 ]; then \
		docker create -v /data --name stf_redisdata $(centos) /bin/true; \
	fi

build: dbdata

	@echo build happy_base
	docker build -t stf  .

	@echo remove containers
	@if [ $(shell cd dev && docker-compose ps -q | wc -l) -ne 0 ]; then \
		docker rm -f $$(docker-compose ps -q); \
	fi

run: dbdata

	@echo start containers
	@if [ $(shell docker ps | grep -ci stf) -eq 0 ]; then \
		docker-compose up -d ; \
	fi

stop: dbdata

	@echo stop containers
	cd dev && docker-compose stop

dev: run

	docker exec -it stf bash -c 'cd /stf; exec bash;'


clean_containers:

	docker ps -a | grep Exit | cut -d ' ' -f 1 | xargs  docker rm

clean_images:

	docker rmi -f $$(docker images -a | grep "<none>" | awk '{print $$3}')

upgrade_containers:

	make stop && make clean_containers && make run
