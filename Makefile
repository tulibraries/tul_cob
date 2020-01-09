up:
	git submodule init
	git submodule update
	docker-compose -f docker-compose.yml -f docker-compose.local.yml up -d
down:
	docker-compose -f docker-compose.yml -f docker-compose.local.yml down
restart:
	docker-compose -f docker-compose.yml -f docker-compose.local.yml restart
tty-app:
	docker-compose -f docker-compose.yml -f docker-compose.local.yml exec app bash
tty-solr:
	docker-compose -f docker-compose.yml -f docker-compose.local.yml exec solr bash
lint:
	docker-compose -f docker-compose.yml -f docker-compose.local.yml exec app rubocop
test:
	docker-compose -f docker-compose.yml -f docker-compose.local.yml exec -e RELEVANCE=y app rake ci
test-js:
	docker-compose -f docker-compose.yml -f docker-compose.local.yml exec app yarn test
load-data:
	docker-compose -f docker-compose.yml -f docker-compose.local.yml exec app rake ingest
