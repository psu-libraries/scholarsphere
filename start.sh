set -e

if [ ${RAILS_ENV:-development} != "production" ]; then
  bundle check || bundle
  yarn
fi

if [ ${APP_ROLE:-app} == "sidekiq" ]; then
    echo "starting sidekiq"
    /app/bin/sidekiq
else
    echo "starting rails"
    rm -f tmp/pids/server.pid
    bundle exec rails db:create
    bundle exec rails db:migrate
    bundle exec rails solr:init
    bundle exec rails s -b '0.0.0.0'
fi
