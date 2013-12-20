#CalCentral

Home of CalCentral. [![Dependency Status](https://gemnasium.com/ets-berkeley-edu/calcentral.png)](https://gemnasium.com/ets-berkeley-edu/calcentral) [![Code Climate](https://codeclimate.com/github/ets-berkeley-edu/calcentral.png)](https://codeclimate.com/github/ets-berkeley-edu/calcentral)
* Master: [![Build Status](https://travis-ci.org/ets-berkeley-edu/calcentral.png?branch=master)](https://travis-ci.org/ets-berkeley-edu/calcentral)
* QA: [![Build Status](https://travis-ci.org/ets-berkeley-edu/calcentral.png?branch=qa)](https://travis-ci.org/ets-berkeley-edu/calcentral)

## Dependencies

* [Bundler](http://gembundler.com/rails3.html)
* [Git](https://help.github.com/articles/set-up-git)
* [JDBC Oracle driver](http://www.oracle.com/technetwork/database/enterprise-edition/jdbc-112010-090769.html)
* [JRuby 1.7.x](http://jruby.org/)
* [PostgreSQL](http://www.postgresql.org/)
* [Rails 3.2.x](http://rubyonrails.org/download)
* [Rubygems](http://rubyforge.org/frs/?group_id=126)
* [Rvm](https://rvm.io/rvm/install/) - Ruby version managers
* [xvfb](XQuartz: http://xquartz.macosforge.org/landing/) - xvfb headless browser, included for Macs with XQuartz

## Installation

1. Install postgres
```bash
brew update
brew install postgresql
initdb /usr/local/var/postgres
```
1. __For Mountain Lion & Mavericks users ONLY:__ Fix Postgres paths as [detailed here](http://nextmarvel.net/blog/2011/09/brew-install-postgresql-on-os-x-lion/).

1. __For Mountain Lion & Mavericks users ONLY:__ If you can connect to Postgres via psql, but not via JDBC (you see "Connection refused" errors in the CalCentral
app log), then edit /usr/local/var/postgres/pg_hba.conf and make sure you have these lines:
```
host    all             all             127.0.0.1/32            md5
host    all             all             samehost                md5
```

1. __For Mountain Lion & Mavericks users ONLY:__ [Install XQuartz](http://xquartz.macosforge.org/landing/) and make sure that /opt/X11/bin is on your PATH.

1. Start postgres, add the user and create the necessary databases. (If your PostgreSQL server is managed externally, you'll probably need to create a schema that matches the database username. See CLC-893 for details.)
```bash
pg_ctl -D /usr/local/var/postgres -l /usr/local/var/postgres/server.log start
psql postgres
create database calcentral_development;
create user calcentral_development with password 'secret';
grant all privileges on database calcentral_development to calcentral_development;
create database calcentral;
create user calcentral with password 'secret';
grant all privileges on database calcentral to calcentral;
create database calcentral_test;
create user calcentral_test with password 'secret';
grant all privileges on database calcentral_test to calcentral_test;
```

1. Fork this repository, then:
```bash
git clone git@github.com:[your_github_acct]/calcentral.git
```

1. Go inside the `calcentral` repository
```bash
cd calcentral
# Answer "yes" if it asks you to trust a new .rvmrc file.
```

1. Install jruby
```bash
rvm get head
rvm install jruby-1.7.8
cd ..
cd calcentral
# Answer "yes" again if it asks you to trust a new .rvmrc file.
```

1. Make JRuby faster, give it lots of RAM, & enable C extensions by running this or put in your .bashrc:
```bash
# for 32-bit JVMs:
export JRUBY_OPTS="-Xcext.enabled=true -J-d32 -J-client -X-C -J-Xms900m -J-Xmx900m -J-XX:MaxPermSize=500m --headless"

# on 64-bit JVMs, which won't respond to -J-client, this may work better:
export JRUBY_OPTS="-Xcext.enabled=true -X-C -J-Xms900m -J-Xmx900m -J-XX:MaxPermSize=500m --headless -J-XX:+TieredCompilation -J-XX:TieredStopAtLevel=1 -J-Xcompile.invokedynamic=false"
```
  * __WARNING__: The -J-d32 setting is optional (32-bit mode starts up a tiny bit quicker in some JVMs).
  * __WARNING__: Do not switch between 32-bit and 64-bit JRuby after your gemset has been initialized (your bundle library will have serious issues). If you do need to change settings, make sure to reinitialize your gemset:
     * ```rvm gemset delete calcentral```
     * (set your JRUBY_OPTS)
     * ```bundle install```

1. Download and install xvfb. On a Mac, you get xvfb by [installing XQuartz](XQuartz: http://xquartz.macosforge.org/landing/)

1. Download the appropriate gems with [Bundler](http://gembundler.com/rails3.html)
```bash
bundle install
```

1. Set up a local settings directory:
```
mkdir ~/.calcentral_config
```
Default settings are loaded from your source code in `config/settings.yml` and `config/settings/ENVIRONMENT_NAME.yml`. For example, the configuration used when running tests with `RAILS_ENV=test` is determined by the combination of `config/settings/test.yml` and `config/settings.yml`.
Because we don't store passwords and other sensitive data in source code, any RAILS_ENV other than `test` requires overriding some default settings.
Do this by creating `ENVIRONMENT.local.yml` files in your `~/.calcentral_config` directory. For example, your `~.calcentral_config/development.local.yml` file may include access tokens and URLs for a locally running Canvas server.
You can also create Ruby configuration files like "settings.local.rb" and "development.local.rb" to amend the standard `config/environments/*.rb` files.

1. Install JDBC driver (for Oracle connection)
  * Download [ojdbc6.jar](http://svn.media.berkeley.edu/nexus/content/repositories/myberkeley/com/oracle/ojdbc6/11.2.0.3/ojdbc6-11.2.0.3.jar)
  * Copy ojdbc6.jar to your project's ./lib folder```

1. Initialize PostgreSQL database tables
```bash
rake db:schema:load db:seed
```

1. Make yourself powerful
```bash
rake superuser:create UID={your numeric CalNet UID}
```

1. Start the server
```bash
rails s
```

1. Access your development server at [localhost:3000](http://localhost:3000/).
Do not use 127.0.0.1:3000, as you will not be able to grant access to bApps.

## Enable live updates

In order to have live updates you'll need to perform the following steps:

1. Install and run memcached

1. Add the following lines to development.local.yml
```yaml
messaging:
  enabled: true
cache:
  store: "memcached"
```

1. Start the server with TorqueBox

## Back-end Testing

Back-end (rspec) tests live in spec/*.

To run the tests from the command line:
```
rspec
```

To run the tests faster, use spork, which is a little server that keeps the Rails app initialized while you change code
and run multiple tests against it. Command line:
```
spork (...wait a minute for startup...)
rspec --drb spec/lib/my_spec.rb
```

You can even run Spork right inside [IntelliJ RubyMine or IDEA](http://www.jetbrains.com/ruby/webhelp/using-drb-server.html).

## Front-end Testing

Front-end [jasmine](http://pivotal.github.com/jasmine/) tests live in spec/javascripts/calcentral/*.

To run the tests headless on firefox run `rake jasmine:ci`.

To view results of front-end tests, run `rake jasmine` in a separate terminal,
then visit [localhost:8888](http://localhost:8888).

## Role-Aware Testing

Some features of CalCentral are accessible only to users with particular roles, such as "student."
These features may be invisible when logged in as yourself. In particular:

- My Academics will only appear in the navigation if logged in as a student. However, the "Oski Bear" test student does not fake data loaded on dev and QA. To test My Academics, log in as user  test-212385 or test-212381 (ask a developer for the passwords to these if you need them). Once logged in as a test student, append "/academics" to the URL to access My Academics (this will change when CLC-1755 is resolved).

## Debugging

### Emulating production mode locally

1. Make sure you have a separate production database. In psql:
```
create database calcentral_production;
grant all privileges on database calcentral_production to calcentral_development;
```

1. In calcentral_config/production.local.yml, you'll need the following entries:
```
secret_token: "Some random 30-char string"
postgres: [credentials for your separate production db (copy/modify from development.local.yml)]
campusdb: [copy from main config/settings.yml, modify if needed]
google_proxy: and canvas_proxy: [copy from development.local.yml]
  application:
    serve_static_assets: true
```

1. Populate the production db by invoking your production settings:
```
RAILS_ENV="production" rake db:schema:load db:seed
```

1. Precompile the assets: [(more info)](http://stackoverflow.com/questions/7275636/rails-3-1-0-actionviewtemplateerrror-application-css-isnt-precompiled)
```bash
bundle exec rake assets:precompile
```

1. Start the server in production mode
```bash
rails s -e production
```

1. If you're not able to connect to Google or Canvas, export the data in the oauth2 from your development db and import them into the same table in your production db.

1. After testing, remove the static assets and generated pages
```bash
bundle exec rake assets:clean
```

### Start the server with TorqueBox

In production we use [TorqueBox](http://torquebox.org/) as this provides us with messaging, scheduling, caching, and daemons.

1. Deploy into TorqueBox (only needs to happen once in a while)
```bash
bundle exec torquebox deploy .
```

1. Start the server
```bash
bundle exec torquebox run -p=3000
```

### Test connection

Make sure you are on the Berkeley network or connected through [preconfigured VPN](https://kb.berkeley.edu/jivekb/entry.jspa?externalID=2665) for the Oracle connection.
If you use VPN, use group #1 (1-Campus_VPN)

### Enable basic authentication

Basic authentication will enable you to log in without using CAS.
This is necessary when your application can't be CAS authenticated or when you're testing mobile browsers.
**Note** only enable this in fake mode or in development.

1. Add the following setting to your `environment.yml` file (e.g. `development.yml`)
```bash
developer_auth:
  enabled: false
  password: topsecret!
```

1. (re)start the server for the changes to take effect.

1. Click on the footer (Berkeley logo) when you load the page.

1. You should be seeing the [Basic Auth screen](http://cl.ly/SA6C). As the login you should use the UID (e.g. 61889, oski) and then password from the settings file.

### "Act As" another user

To help another user debug an issue, you can "become" them on CalCentral. To assume the identity of another user, you must:

- Currently be logged in as a designated superuser
- Be accessing a machine/server which the other user has previously logged into (e.g. from localhost, you can't act as a random student, since that student has probably never logged in at your terminal)
- Have enabled act_as in settings.yml (features:)

Access the URL:

```
https://[hostname]/act_as?uid=123456
```

where 123456 is the UID of the user to emulate.

n.b.: The Act As feature will only reveal data from data sources we control, e.g. Canvas. Google data will be completely suppressed, __EXCEPT__ for test users. The following user uids have been configured as test users.
* 11002820 - "Tammi Chang"
* 61889 - "Oski Bear"
* All IDs listed on the ["Universal Calnet Test IDs"](https://wikihub.berkeley.edu/display/calnet/Universal+Test+IDs) page

To become yourself again, access

```
https://[hostname]/stop_act_as
```

### Logging

Logging behavior and destination can be controlled from the command line or shell scripts via env variables:

* `LOGGER_STDOUT=false` - Only log to the default files
* `LOGGER_STDOUT=true` - Log to standard output as well as the default files
* `LOGGER_STDOUT=only` - Only log to standard output
* `LOGGER_LEVEL=DEBUG` - Set logging level; acceptable values are 'FATAL', 'ERROR', 'WARN', 'INFO', and 'DEBUG'

### Tips

1. On Mac OS X, to get RubyMine to pick up the necessary environment variables, open a new shell, set the environment variables, and:
```bash
/Applications/RubyMine.app/Contents/MacOS/rubymine &
```

1. If you want to explore the Oracle database on Mac OS X, use [SQL Developer](http://www.oracle.com/technetwork/developer-tools/sql-developer/overview/index.html)

1. We support **source maps** for SASS in development mode. There is a [great blog post](http://fonicmonkey.net/2013/03/25/native-sass-scss-source-map-support-in-chrome-and-rails/) explaining how to set it up and use it.

### Styleguide

See [docs/styleguide.md](docs/styleguide.md)

## Recording fake data feeds and timeshifting them

Make sure your testext.local.yml file has real connections to real external services that are fakeable (Canvas, Google, etc).
Now do:

```bash
rake vcr:record
rake vcr:prettify
```

* vcr:record can also take a SPEC=".../my_favorite_spec.rb" to help limit the recordings.
* vcr:prettify can also take a REGEX_FILTER="my_raw_recording.json" to target a specific raw file.

You can now find the prettified files in fixtures/pretty_vcr_recordings. You can edit these files to put in tokens that
will be substituted on server startup. See config/initializers/timeshift.rb for the dictionary of substitutions. Edit
 the debug_json property of each response, and timeshift.rb will automatically convert debug_json to the format actually
 used by VCR.

## Rake tasks:

To view other rake task for the project: ```rake -T```

* ```rake spec:xml``` - Runs rake spec, but pipes the output to xml using the rspec_junit_formatter gem, for JUnit compatible test result reports
* ```rake vcr:record``` - Refresh vcr recordings and reformats the fixtures with formatted JSON output. Will also parse the reponse body's string into json output for legibility.
* ```rake vcr:list``` - List the available recordings captured in the fixtures.

## Memcached tasks:

A few rake tasks to help monitor statistics and more:

* ```rake memcached:clear_stats``` - Reset memcached stats from all cluster nodes
* ```rake memcached:empty``` - Invalidate all memcached keys from all cluster nodes
* ```rake memcached:get_stats``` - Fetch memcached stats from all cluster nodes

* Generally, if you `rake memcached:empty` ( __WARNING:__ do not run on the production cluster unless you know what you're doing), you should follow with an `rake memcached:clear_stats`.
* All three task take the optional param of "hosts." So, if say you weren't running these tasks on the cluster layers themselves, or only wanted to tinker with a certain subset of clusters: `rake memcached:get_stats hosts="localhost:11212,localhost:11213,localhost:11214"`

## Using the feature toggle:

To selectively enable/disable a feature, add a property to the "features" section of settings.yml, e.g.:

```
features:
  wizbang: false
  neato: true
```

After server restart, these properties will appear in each users' status feed. You can now use ```ng:show``` in Angular to wrap the feature, e.g.:

```html
<div data-ng-show="user.profile.features.neato">
  Some neato feature...
</div>
```
or, depending on the feature, it may make more sense to disable it in erb (so that Angular controllers are never invoked at all):

```
<% if Settings.features.neato %>
  <%= render 'templates/widgets/notifications' %>
<% end %>
```

## Keeping developer seed data updated

seeds.rb is intended for use only on developer machines, so they have a semi-realistic copy of production lists of
superusers, links, etc. ./db/developer-seed-data.sql has the data used by rake db:seed. Occasionally we'll want to
update it from production. To do that, log into a prod node and do:
```
pg_dump calcentral --inserts --clean -f developer-seed-data.sql -t link_categories \
-t link_categories_link_sections -t link_sections -t link_sections_links -t links \
-t links_user_roles -t user_auths -t user_roles -t user_whitelists \
-h postgres-hostname -p postgres-port-number -U calcentral
```

Take that file, developer-seed-data.sql, and edit it to remove the "REVOKE" and "GRANT" statements at the bottom,
since those will conflict with local permissions. Copy that file into your source tree and get it merged into master.
