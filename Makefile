#Defaults
include .env
export #exports the .env variables

DOCKER_FLAGS := COMPOSE_DOCKER_CLI_BUILD=1 DOCKER_BUILDKIT=1
ifeq ($(CI), true)
	DOCKER := $(DOCKER_FLAGS) docker-compose -p tul_cob -f docker-compose.ci.yml
	LINT_CMD := ./bin/rubocop
	TEST_CMD := ./bin/rake ci
	DOCKERHUB_LOGIN := docker login -u ${DOCKERHUB_USER} -p ${DOCKERHUB_PASSWORD}
else
	DOCKER := $(DOCKER_FLAGS) docker-compose -f docker-compose.yml -f docker-compose.local.yml
	LINT_CMD := rubocop
	TEST_CMD := rake ci
endif

up:
	git submodule init
	git submodule update
	@$(DOCKERHUB_LOGIN)
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
test-libguides-relevance:
	bundle exec rspec spec/relavance/lib_guides_spec.rb --tag lib_guides_relevance
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

ci-setup-db:
	$(DOCKER) exec app bundle exec rake db:migrate

BASE_IMAGE ?= harbor.k8s.temple.edu/library/ruby:2.7-alpine
IMAGE ?= tulibraries/tul_cob
VERSION ?= $(DOCKER_IMAGE_VERSION)
HARBOR ?= harbor.k8s.temple.edu
CLEAR_CACHES=no
CI ?= false
PLATFORM ?= linux/x86_64

run:
	@docker run --name=cob -p 127.0.0.1:3001:3000/tcp \
		--platform $(PLATFORM) \
		-e "ALMA_API_KEY=$(ALMA_API_KEY)" \
		-e "ALMA_AUTH_SECRET=$(ALMA_AUTH_SECRET)" \
		-e "ALMA_DELIVERY_DOMAIN=$(ALMA_DELIVERY_DOMAIN)" \
		-e "ALMA_INSTITUTION_CODE=$(ALMA_INSTITUTION_CODE)" \
		-e "AZ_CLIENT_ID=$(AZ_CLIENT_ID)" \
		-e "AZ_CLIENT_SECRET=$(AZ_CLIENT_SECRET)" \
		-e "COB_DB_HOST=$(COB_DB_HOST)" \
		-e "COB_DB_NAME=$(COB_DB_NAME)" \
		-e "COB_DB_PASSWORD=$(COB_DB_PASSWORD)" \
		-e "COB_DB_USER=$(COB_DB_USER)" \
		-e "EXECJS_RUNTIME=Disabled" \
		-e "LIB_GUIDES_API_KEY=$(LIB_GUIDES_API_KEY)" \
		-e "LIB_GUIDES_SITE_ID=$(LIB_GUIDES_SITE_ID)" \
		-e "OCLC_WS_KEY=$(OCLC_WS_KEY)" \
		-e "RAILS_ENV=production" \
		-e "RAILS_SERVE_STATIC_FILES=yes" \
		-e "SECRET_KEY_BASE=$(SECRET_KEY_BASE)" \
		-e "SOLRCLOUD_HOST=$(SOLRCLOUD_HOST)" \
		-e "SOLRCLOUD_PASSWORD=$(SOLRCLOUD_PASSWORD)" \
		-e "SOLRCLOUD_USER=$(SOLR_AUTH_USER)" \
		-e "K8=yes" \
		-v `pwd`/config/alma.yml.local:/app/config/alma.yml \
		-v `pwd`/config/bento.yml:/app/config/bento.yml \
		-v `pwd`/config/secrets.yml:/app/config/secrets.yml \
		--rm -it \
		$(HARBOR)/$(IMAGE):$(VERSION)

build:
	@docker build --build-arg SECRET_KEY_BASE=$(SECRET_KEY_BASE) \
    --build-arg BASE_IMAGE=$(BASE_IMAGE) \
		--platform $(PLATFORM) \
		--tag $(HARBOR)/$(IMAGE):$(VERSION) \
		--tag $(HARBOR)/$(IMAGE):latest \
		--file .docker/app/Dockerfile.prod \
		--progress plain \
		--no-cache .  | tee ./log/cob-docker-build.log

shell:
	@docker run --rm -it \
		--entrypoint=sh --user=root \
		$(HARBOR)/$(IMAGE):$(VERSION)

gitlab-lint:
	@if [ $(CI) == false ]; \
		then \
			hadolint .docker/app/Dockerfile.prod; \
		fi

scan:
	@if [ $(CLEAR_CACHES) == yes ]; \
		then \
			trivy image -c $(HARBOR)/$(IMAGE):$(VERSION); \
		fi
	@if [ $(CI) == false ]; \
		then \
			trivy image $(HARBOR)/$(IMAGE):$(VERSION); \
		fi

deploy: scan gitlab-lint
	@docker push $(HARBOR)/$(IMAGE):$(VERSION) \
	# This "if" statement needs to be a one liner or it will fail.
	# Do not edit indentation
	@if [ $(VERSION) != latest ]; \
		then \
			docker push $(HARBOR)/$(IMAGE):latest; \
		fi
