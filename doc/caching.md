# Caching in Force and Microgravity

Caching is done using Redis. In production, we use the same redis instance for both Force and Microgravity. Currently, we only use Redis to cache API get
requests by overriding Backbone.sync with
[backbone-cache-sync](https://github.com/artsy/backbone-cache-sync).

## Redis Dashboard

- visit https://dashboard.heroku.com/apps/force-production/resources
- click 'openredis'
- https://openredis.com/instances/3848

## Redis-cli
- `brew install redis`
- visit the Redis Dashboard (see previous section)
- enter the command highlighted under 'From the command line, in your local environment': https://www.dropbox.com/s/q99gzgdvgh8bxc1/Screenshot%202014-01-06%2018.11.32.png
- Redis-cli Docs (some commands like `keys` do not work): http://redis.io/commands

## Clear entire cache

- Start the CLI
- `$ flushall`
- done!

## Remove a specific key

Keys are the url for the respective api endpoint

- Start the CLI
- `$ RANDOMKEY` to get a sample key
- '$ del "https://artsy.net/foo"`
- done!
