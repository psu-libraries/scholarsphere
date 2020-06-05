FROM psul/ruby:20200604-2.6.6-node-12 as base

COPY bin/vaultshell /usr/local/bin/

RUN useradd -u 2000 app -d /app
RUN mkdir /app/tmp
RUN chown -R app /app
USER app

COPY Gemfile Gemfile.lock /app/
COPY --chown=app vendor/ vendor/
RUN gem install bundler:2.1.4
RUN bundle install --path vendor/bundle && \
  rm -rf /app/.bundle/cache && \
  rm -rf /app/vendor/bundle/ruby/*/cache


COPY package.json yarn.lock /app/
RUN yarn --frozen-lockfile && \
  rm -rf /app/.cache && \
  rm -rf /app/tmp


COPY --chown=app . /app

CMD ["./entrypoint.sh"]

# Final Target
FROM base as production

RUN RAILS_ENV=production \
  DEFAULT_URL_HOST=localhost \
  SECRET_KEY_BASE=$(bundle exec rails secret) \
  AWS_BUCKET=bucket \
  AWS_ACCESS_KEY_ID=key \
  AWS_SECRET_ACCESS_KEY=secret \
  AWS_REGION=us-east-1 \
  bundle exec rails assets:precompile && \
  rm -rf /app/.cache/ && \
  rm -rf /app/node_modules/.cache/ && \
  rm -rf /app/tmp/



CMD ["./entrypoint.sh"]
