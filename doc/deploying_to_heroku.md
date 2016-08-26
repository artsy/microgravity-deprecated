# Deploying to Heroku

Microgravity is deployed to Heroku's [microgravity-staging](https://dashboard.heroku.com/apps/microgravity-staging) and [microgravity-production](https://dashboard.heroku.com/apps/microgravity-production) applications.

The Heroku application(s) need to be configured with `NODE_ENV` set to *staging* or *production*, as follows (using *staging* as an example).

```
$ heroku config:add NODE_ENV=staging --app=microgravity-staging
```

## DNS

[DynECT](http://manage.dynect.com) points [m.artsy.net](http://m.artsy.net) and [m.staging.artsy.net](http://m.staging.artsy.net) to Microgravity.

## Deployment Tasks

Deployment tasks are set-up as [deploy-microgravity-staging](http://joe.artsy.net:9000/job/deploy-microgravity-staging) and [deploy-microgravity-production](http://joe.artsy.net:9000/job/deploy-microgravity-production) on Jenkins.

```
gem install heroku
npm install
make deploy-staging
```