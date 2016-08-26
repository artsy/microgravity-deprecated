#
# Make -- the OG build tool.
# Add any build tasks here and abstract complex build scripts into `lib` that can
# be run in a Makefile task like `coffee lib/build_script`.
#
# Remember to set your text editor to use 4 size non-soft tabs.
#

BIN = node_modules/.bin

# Start the server
s:
	$(BIN)/nf start

# Start the server with the OSS env vars instead of the developer's `.env`
oss:
	APP_URL=http://localhost:5000 APPLICATION_NAME=force-development $(BIN)/nf start --env .env.oss

# Start the server using forever
sf:
	$(BIN)/forever $(BIN)/coffee index.coffee

# Start the server pointing to staging
ss:
	APPLICATION_NAME=microgravity-staging METAPHYSICS_ENDPOINT=https://metaphysics-staging.artsy.net API_URL=https://stagingapi.artsy.net ARTSY_URL=https://staging.artsy.net POSITRON_URL=http://stagingwriter.artsy.net $(BIN)/nf start

# Start the server pointing to staging with cache
ssc:
	OPENREDIS_URL=http://localhost:6379 APPLICATION_NAME=microgravity-production API_URL=https://stagingapi.artsy.net POSITRON_URL=http://writer.artsy.net make s

# Start the server pointing to production
sp:
	APPLICATION_NAME=microgravity-production API_URL=https://api.artsy.net ARTSY_URL=https://artsy.net POSITRON_URL=http://writer.artsy.net make s

# Start server pointing to production with cache
spc:
	OPENREDIS_URL=http://localhost:6379 APPLICATION_NAME=microgravity-production API_URL=https://api.artsy.net POSITRON_URL=http://writer.artsy.net make s

# Run all of the tests
test:
	$(BIN)/ezel-assets
	$(BIN)/mocha $(shell find test -name '*.coffee' -not -path 'test/helpers/*')
	$(BIN)/mocha $(shell find components/*/test -name '*.coffee' -not -path 'test/helpers/*')
	$(BIN)/mocha $(shell find components/**/*/test -name '*.coffee' -not -path 'test/helpers/*')
	$(BIN)/mocha $(shell find apps/*/test -name '*.coffee' -not -path 'test/helpers/*')
	$(BIN)/mocha $(shell find apps/*/**/*/test -name '*.coffee' -not -path 'test/helpers/*')

# Sets up the test server to see what integration tests are using.
test-s:
	$(BIN)/coffee test/helpers/servers.coffee

# Runs all the necessary build tasks to push to staging or production
deploy:
	$(BIN)/ezel-assets
	$(BIN)/bucket-assets --bucket microgravity-$(env)
	heroku config:set COMMIT_HASH=$(shell git rev-parse --short HEAD) --app=microgravity-$(env)
	git push --force git@heroku.com:microgravity-$(env).git

.PHONY: test
