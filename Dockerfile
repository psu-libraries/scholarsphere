FROM ruby:2.6.3 as base

WORKDIR /app

ENV TZ=America/New_York

## NodeJS
ENV NODE_VERSION 12.9.1
RUN mkdir /usr/local/nvm
ENV NVM_DIR /usr/local/nvm
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash
ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH


RUN . $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default

RUN npm install -g yarn@1.19.1

### Envconsul
RUN curl -Lo /tmp/envconsul.zip https://releases.hashicorp.com/envconsul/0.9.0/envconsul_0.9.0_linux_amd64.zip && \
    unzip /tmp/envconsul.zip -d /bin && \
    rm /tmp/envconsul.zip

RUN useradd -u 10000 app -d /app
RUN chown -R app /app
USER app

COPY Gemfile Gemfile.lock /app/
RUN gem install bundler:2.0.2
RUN bundle install --path vendor/bundle

COPY package.json yarn.lock /app/
RUN yarn --frozen-lockfile

COPY --chown=app . /app

CMD ["./entrypoint.sh"]

# Build targets for testing
FROM base as rspec
CMD [ "/app/bin/ci-rspec" ]

FROM base as eslint
CMD [ "/app/bin/ci-eslint" ]

FROM base as sidekiq
CMD [ "/app/bin/sidekiq" ]

FROM base as niftany
CMD [ "/app/bin/ci-niftany" ]

# Final Target
FROM base as production

RUN RAILS_ENV=production SECRET_KEY_BASE=$(bundle exec rails secret) AWS_BUCKET=bucket AWS_ACCESS_KEY_ID=key AWS_SECRET_ACCESS_KEY=secret AWS_REGION=us-east-1 bundle exec rails assets:precompile
