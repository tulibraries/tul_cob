DOCKER := docker-compose -f .docker/docker-compose.yml -f .docker/docker-compose.local.yml
CI-DOCKER := docker-compose -p tul_cob -f .docker/docker-compose.ci.yml

ci-up:
	git submodule init
	git submodule update
	$(CI-DOCKER) up -d

ci-copy-bundle-files:
	if [ -d vendor/bundle ]; then docker cp vendor/bundle tul_cob_app_1:/app/vendor/bundle; fi

ci-copy-bundle-files-to-local:
	docker cp tul_cob_app_1:/app/vendor/bundle vendor/bundle

ci-copy-node-modules:
	if [ -d node_modules ]; then  docker cp node_modules tul_cob_app_1:/app/node_modules; fi

ci-copy-node-modules-to-local:
	docker cp tul_cob_app_1:/app/node_modules node_modules 

ci-bundle-install:
	$(CI-DOCKER) exec app bundle install --path vendor/bundle
	$(CI-DOCKER) exec app bundle binstubs --all
	$(CI-DOCKER) exec app bundle binstubs bundler --force

ci-yarn-install:
	$(CI-DOCKER) exec app yarn install --frozen-lockfile

ci-lint:
	$(CI-DOCKER) exec app ./bin/rubocop

ci-test:
	$(CI-DOCKER) exec -e RELEVANCE=y app ./bin/rake ci

ci-test-js:
	$(CI-DOCKER) exec app yarn test

up:
	git submodule init
	git submodule update
	$(DOCKER) up -d
down:
	$(DOCKER) down
restart:
	$(DOCKER) exec app bundle install
	$(DOCKER) exec app bundle exec rails restart
tty-app:
	$(DOCKER) exec app bash
tty-solr:
	$(DOCKER) exec solr bash
lint:
	$(DOCKER) exec app rubocop
test:
	$(DOCKER) exec -e RELEVANCE=y app rake ci
test-js:
	$(DOCKER) exec app yarn test
load-data:
	$(DOCKER) exec app rake ingest
reload-configs:
	$(DOCKER) exec solr solr-configs-reset
ps:
	$(DOCKER) ps
attach:
	# Used for debugging the app.
	@echo
	@echo '*********************************'
	@echo '*** Attaching to app container. *'
	@echo '*** Detach with CTRL-p CTRL-q   *'
	@echo '*********************************'
	@echo
	@bin/attach.sh tul_cob_app
