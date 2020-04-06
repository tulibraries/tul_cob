DOCKER := docker-compose -f docker-compose.yml -f docker-compose.local.yml

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
	e.local.yml exec app rake ingest
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
