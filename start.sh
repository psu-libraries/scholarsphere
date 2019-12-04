
if [ ${RAILS_ENV:-development} != "production" ]; then
  bundle check || bundle
fi

echo "starting rails"
rm -f tmp/pids/server.pid
bundle exec rails db:create
bundle exec rails db:migrate
bundle exec rails solr:init
bundle exec rails s -b '0.0.0.0'
