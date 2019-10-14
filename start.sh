

if [ ${APP_ROLE:-app} == "sidekiq" ]; then
    echo "starting sidekiq"
    bundle exec sidekiq
else
    echo "starting rails"
    bundle exec rails db:create
    bundle exec rails db:migrate
    bundle exec rails s -b '0.0.0.0'
fi