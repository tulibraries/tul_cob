ifeq ($(CI), true)
	DOCKER := docker-compose -p tul_cob -f docker-compose.ci.yml
	LINT_CMD := ./bin/rubocop
	TEST_CMD := ./bin/rake ci
else
	DOCKER := docker-compose -f docker-compose.yml -f docker-compose.local.yml
	LINT_CMD := rubocop
	TEST_CMD := rake ci
endif

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
	$(DOCKER) exec app $(LINT_CMD)
test:
	$(DOCKER) exec app $(TEST_CMD)
test-js:
	$(DOCKER) exec app yarn test
load-data:
	$(DOCKER) exec -e DO_INGEST=y app rake tul_cob:solr:load_fixtures
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

# CI Specific Targets
ci-copy-bundle-files-to-local:
	docker cp tul_cob_app_1:/app/vendor/bundle vendor/

ci-copy-node-modules-to-local:
	docker cp tul_cob_app_1:/app/node_modules .

ci-bundle-install:
	$(DOCKER) exec app bundle install --path vendor/bundle
	$(DOCKER) exec app bundle binstubs --all
	$(DOCKER) exec app bundle binstubs bundler --force

ci-yarn-install:
	$(DOCKER) exec app yarn install --frozen-lockfile
