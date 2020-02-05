ARG BASETAG=base
FROM harbor.dsrd.libraries.psu.edu/library/scholarsphere:${BASETAG} as cache
FROM harbor.dsrd.libraries.psu.edu/library/scholarsphere:${BASETAG} as base

ENV TZ=America/New_York

WORKDIR /app

USER app

COPY Gemfile Gemfile.lock /app/
COPY --from=cache /app/vendor/ /app/vendor/
RUN bundle install --path vendor/bundle

COPY package.json yarn.lock /app/
RUN yarn --frozen-lockfile

COPY --chown=app . /app

CMD ["./entrypoint.sh"]

# Final Target
FROM base as production

RUN RAILS_ENV=production DEFAULT_URL_HOST=localhost SECRET_KEY_BASE=$(bundle exec rails secret) AWS_BUCKET=bucket AWS_ACCESS_KEY_ID=key AWS_SECRET_ACCESS_KEY=secret AWS_REGION=us-east-1 bundle exec rails assets:precompile

CMD ["./entrypoint.sh"]
