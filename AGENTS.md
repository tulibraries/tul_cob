# AGENTS GUIDE FOR TUL_COB REPO
## Purpose
- This file guides agentic coding work for the entire repository root.
- No additional AGENTS.md exist; this governs all subdirectories.
- No Cursor or Copilot instruction files were found in this repo.
- Default branch tooling is Ruby on Rails with Blacklight + Webpacker.

## Safety and scope
- Do not read files outside this repository.
- Never inspect user dotfiles like ~/.ssh, ~/.aws, ~/.npmrc, ~/.gitconfig.
- Ask before running shell commands that inspect environment variables.
- Protect secrets: config/*.yml.example are templates; avoid committing real keys.

## Key paths
- Rails app code lives in `app/` with views, controllers, models, components.
- Background tasks and rake logic live in `lib/tasks/`.
- Specs live in `spec/` for Ruby and `spec/javascript/` for Jest.
- Asset pipeline uses Webpacker in `app/javascript/` and packs in `app/javascript/packs`.
- Sample data lives in `sample_data/`; Solr configs under `solr/`.
- Docker support files live in `.docker/`, docker-compose files at repo root.

## Ruby version and framework
- Target Ruby version is 3.4 per `.rubocop.yml`.
- Rails version is 7.2.2.2 (Gemfile) with Blacklight 7.x.
- Default database for tests is SQLite (see Gemfile group :test).
- Puma 7.1.0 is the app server; webpacker 6 rc drives JS builds.

## Quick start commands
- Install deps: `bundle install` (Ruby) and `bundle exec yarn install` (JS) locally.
- Copy configs: `cp config/secrets.yml.example config/secrets.yml` and same for alma/bento.
- DB setup: `bundle exec rails db:migrate` after configs are in place.
- Run solr locally via the documented ansible-playbook-solrcloud or docker-compose.
- Start Rails dev server: `bundle exec rails server` (requires SOLR_URL set).
- Docker up: `make up`; down: `make down`; restart: `make restart`.
- Attach to containers: `make tty-app` for app, `make tty-solr` for Solr.

## Build and asset notes
- Webpacker build is invoked automatically via Rails; packs live in `app/javascript/packs`.
- No standalone frontend build command beyond webpacker; rely on Rails assets pipeline.
- For production image build: `make build` with PLATFORM/ASSETS_PRECOMPILE overrides.
- For debugger image build: `make build-debugger`.
- Build logs output to `log/cob-docker-build*.log`.

## Linting commands
- Ruby lint (local): `bundle exec rubocop`.
- Ruby lint via Docker: `make lint` (runs inside app container).
- CI lint uses `bundle exec rubocop` when CI=true in Makefile.
- No ESLint config present; prefer manual review and RuboCop for Ruby.
- Use `bundle exec rubocop -A` for autocorrectable offenses when acceptable.

## Test commands (Ruby)
- Full suite with fixture ingest: `bundle exec rails ci` (invokes Rake task :ci).
- Standard suite without ingest: `bundle exec rspec` (ensure Solr fixtures loaded first).
- Dockerized tests: `make test` (runs rails ci inside app container).
- Specific spec example: `bundle exec rspec spec/controllers/items_controller_spec.rb:12`.
- Tag-based example: `bundle exec rspec spec/relavance/lib_guides_spec.rb --tag lib_guides_relevance`.
- System/JS Capybara uses headless Chrome; ensure chromium/chromedriver installed (brew install chromiumdriver).
- DatabaseCleaner truncation strategy runs before suite (see spec/rails_helper.rb).

## Test commands (JavaScript)
- All JS tests: `bundle exec yarn test` (Jest, roots at spec/javascript).
- Dockerized JS tests: `make test-js`.
- Single JS test file: `yarn test --runTestsByPath spec/javascript/path/to_spec.js`.
- Watch mode: `bundle exec yarn test --watch` (avoid in CI).
- Jest uses jsdom environment and setup files in `spec/javascript/setup/`.

## Data and Solr tasks
- Load test fixtures into Solr: `bundle exec rails tul_cob:solr:load_fixtures`.
- Include sample data ingest by setting `DO_INGEST=y` before the load task.
- Ingest a single XML file: `bundle exec cob_index ingest sample_data/alma_bibs.xml`.
- Ingest via rake shortcut: `bundle exec rake ingest[sample_data/file.xml]`.
- Prevent accidental production ingest: tasks abort when Solr URL contains production host.
- Clean Solr index: `bundle exec rails tul_cob:solr:clean` (defined in tul_cob:solr namespace).
- Reload electronic notes: `bundle exec rake reload_electronic_notes[/tmp]` (path optional).

## Running locally with Docker
- Compose uses docker-compose.yml + docker-compose.local.yml by default.
- CI uses docker-compose.ci.yml automatically when CI=true.
- Makefile exports .env variables; ensure .env exists with SOLR_URL and secrets.
- To add test browser deps in CI image: `make add-testing-deps` (apk adds chromium packages).
- To copy bundle or node_modules from container: `make ci-copy-bundle-files-to-local` or `make ci-copy-node-modules-to-local`.
- Use `make attach` to attach to running app container without stopping it.

## Logging and monitoring
- Honeybadger 6.x is present; prefer letting exceptions bubble for reporting.
- Use `Rails.logger` for diagnostics; avoid puts in app code (ok in rake tasks when scoped).
- Skylight badge present; performance traces may be configured.

## Error handling guidance
- Fail fast on configuration: raise or abort when required ENV/config is missing (see rake tasks).
- Prefer exceptions over silent nil; avoid broad rescue unless logging and re-raising.
- When rescuing, log actionable context and re-raise or return structured result.
- Avoid swallowing network errors to external services (Alma/Primo); surface via Honeybadger.
- In controllers, use Rails standard rescues and render appropriate status codes.

## Import and dependency guidelines
- Ruby: require minimal files; favor Rails autoload paths under `app/`.
- Keep Gemfile additions scoped; pin versions when upstream repos used (see existing git-sourced gems).
- JavaScript: prefer ES module `import` syntax in webpacker packs; avoid global requires.
- Keep JS dependencies declared in package.json; lock with yarn.lock.

## Formatting rules (Ruby)
- RuboCop enabled cops enforce double quotes for strings.
- Frozen string literal comment required on Ruby files (Style/FrozenStringLiteralComment enforced).
- Two-space indentation, no tabs; align end with variable for assignments.
- Enforce spaces after commas/colons, around operators, and inside braces per RuboCop layout cops.
- Use hash 1.9 syntax `{ key: value }`.
- Parentheses required on method definitions with params (Style/MethodDefParentheses).
- Avoid trailing whitespace and blank lines with spaces.

## Comments
- Do not add code comments unless explicitly instructed.

## Naming conventions
- Ruby classes/modules: CamelCase; files snake_case to match class names.
- Methods/variables: snake_case; constants: SCREAMING_SNAKE_CASE.
- Controllers end with `Controller`; helpers with `Helper`; jobs/services named for responsibility.
- RSpec: describe classes/modules with full constant name; feature/system specs use human titles.

## Rails patterns
- Keep queries in models or service objects; controllers thin and RESTful.
- Use concerns only when shared behavior is substantial and intentional.
- Use strong parameters in controllers for permitted attributes.
- Prefer partials and view components for shared view logic (ViewComponent helpers included).
- Use i18n for strings where feasible; avoid inline HTML strings in controllers.

## JavaScript patterns
- Stimulus controllers live under `app/javascript/controllers`; follow Stimulus naming (foo_controller.js).
- Packs in `app/javascript/packs` should import only necessary controllers/components.
- Avoid direct DOM mutation when Stimulus hooks exist; prefer data-controller targets.
- Use fetch with polyfills already present; prefer async/await for readability.
- Keep Bootstrap integrations via data attributes; avoid jQuery unless necessary (still available).

## Testing style (Ruby)
- Place shared helpers in `spec/support`; already auto-required in rails_helper.
- Use FactoryBot for data setup; factories live under spec/factories (auto-loaded via factory_bot_rails).
- System/feature specs use Capybara headless chrome (`:chrome_headless` driver configured).
- DatabaseCleaner truncation strategy in before(:suite); leave transactional fixtures enabled.
- For controller specs include Devise test helpers (already configured).
- Use rspec metadata `:type` inferred from directory; avoid duplicating `_spec.rb` in support files.
- Prefer expect syntax; avoid should syntax.

## Testing style (JavaScript)
- Jest runs in jsdom; DOM helpers can rely on mutationobserver shim.
- Mocks: jest-fetch-mock is preconfigured; enable with `fetchMock.enableMocks()` if needed per test.
- Keep setup in `spec/javascript/setup` minimal; prefer per-test initialization.
- Name test files `*_test.js` or `*_spec.js` under spec/javascript.
- Use `--runTestsByPath` for targeted runs to speed feedback.

## Performance considerations
- When ingesting data locally, prefer limiting to needed fixtures to avoid long Solr runs.
- Avoid N+1 queries; consider includes on ActiveRecord queries in controllers/search builders.
- Use pagination and scopes provided by Blacklight; avoid manual offset/limit unless necessary.

## Security considerations
- Never commit real API keys; use example configs for references.
- For OmniAuth and Devise, ensure authenticity tokens are respected; avoid disabling CSRF.
- Validate external URLs before ingest; rake tasks already block production Solr endpoints.

## Git and workflow
- Default rake `ci` task runs when no task provided; avoid redefining default.
- Do not commit node_modules or vendor/bundle; both excluded by default.
- Follow existing commit message style from git log; keep changes scoped.
- Prefer small PRs with clear test evidence; include commands run.
- When adding or updating specs, use real data examples (e.g., actual call numbers, titles, or URLs from fixtures) instead of placeholder strings.

## Documentation updates
- Update this AGENTS.md when adding new build/test workflows or style rules.
- Mirror new scripts in README and Makefile targets to keep guidance accurate.
- Keep line-oriented notes concise to aid future agents.

## Contact points
- Blacklight and indexing dependencies are in related repos listed in README.
- Alma/Primo keys are required for certain features; coordinate with maintainers for secrets.
- For Solr schema or fixture changes, update corresponding repos (cob_index, tul_cob-*-solr).

## Final reminders
- Run `bundle exec rails ci` before finishing significant backend changes.
- Run `bundle exec yarn test --runTestsByPath ...` for JS changes touching packs/controllers.
- Keep RuboCop clean; adhere to formatting rules above.
- Ensure Solr fixtures are loaded for specs that query search indices.
- Respect system rule about environment-variable inspection commands.
