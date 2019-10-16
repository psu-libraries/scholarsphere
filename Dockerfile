FROM ruby:2.6.3 as production

WORKDIR /app

ENV TZ=America/New_York

# Install system deps
RUN apt-get update && \
    apt-get install ffmpeg -y 


## NodeJS
ENV NODE_VERSION 12.9.1
RUN mkdir /usr/local/nvm
ENV NVM_DIR /usr/local/nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash
ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH


RUN . $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default

RUN npm install -g yarn

### Envconsul
RUN curl -Lo /tmp/envconsul.zip https://releases.hashicorp.com/envconsul/0.9.0/envconsul_0.9.0_linux_amd64.zip && \
    unzip /tmp/envconsul.zip -d /bin && \
    rm /tmp/envconsul.zip



COPY Gemfile Gemfile.lock /app/
COPY package.json yarn.lock /app/
RUN gem install bundler

RUN useradd -u 10000 app -d /app
RUN chown -R app /app
USER app

RUN bundle install --frozen --path vendor/bundle


RUN chown -R app /app
COPY --chown=app . /app


RUN RAILS_ENV=production SECRET_KEY_BASE=$(bundle exec rails secret) aws_bucket=bucket aws_access_key_id=key aws_secret_access_key=access aws_region=us-east-1 bundle exec rails assets:precompile

CMD ["./entrypoint.sh"]

# Build targets for testing
FROM production as rspec
CMD /app/bin/ci-rspec

FROM production as eslint
CMD /app/bin/ci-eslint

FROM production as niftany
CMD /app/bin/ci-niftany

# Final Target
FROM production as final


