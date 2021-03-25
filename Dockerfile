FROM harbor.k8s.libraries.psu.edu/library/ruby-2.7.1-node-12:20210223 as base
ARG UID=2000

COPY bin/vaultshell /usr/local/bin/
USER root
RUN apt-get update && \
   apt-get install --no-install-recommends -y shared-mime-info && \
   rm -rf /var/lib/apt/lists*

RUN useradd -u $UID app -d /app
RUN mkdir /app/tmp
RUN chown -R app /app
USER app

COPY Gemfile Gemfile.lock /app/
COPY --chown=app vendor/ vendor/
RUN gem install bundler:2.1.4
RUN bundle config set path 'vendor/bundle'
RUN bundle install && \
  rm -rf /app/.bundle/cache && \
  rm -rf /app/vendor/bundle/ruby/*/cache


COPY package.json yarn.lock /app/
RUN yarn --frozen-lockfile && \
  rm -rf /app/.cache && \
  rm -rf /app/tmp


COPY --chown=app . /app

ENTRYPOINT [ "/app/bin/entrypoint" ]

CMD ["/app/bin/startup"]

# Final Target
FROM base as production

# Clean up Bundle
RUN bundle install --without development test && \
  bundle clean && \
  rm -rf /app/.bundle/cache && \
  rm -rf /app/vendor/bundle/ruby/*/cache

RUN RAILS_ENV=production \
  DEFAULT_URL_HOST=localhost \
  SECRET_KEY_BASE=rails_bogus_key \
  AWS_BUCKET=bucket \
  AWS_ACCESS_KEY_ID=key \
  AWS_SECRET_ACCESS_KEY=secret \
  AWS_REGION=us-east-1 \
  bundle exec rails assets:precompile && \
  rm -rf /app/.cache/ && \
  rm -rf /app/node_modules/.cache/ && \
  rm -rf /app/tmp/


ENTRYPOINT [ "/app/bin/entrypoint" ]

CMD ["/app/bin/startup"]
