FROM elixir:1.5
ARG AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY

WORKDIR /root

# Configure Git to use HTTPS in order to avoid issues with the internal MBTA network
RUN git config --global url.https://github.com/.insteadOf git://github.com/

# Install Hex+Rebar
RUN mix local.hex --force && \
  mix local.rebar --force

# Install node/npm
# Instructions from https://nodejs.org/en/download/package-manager/#debian-and-ubuntu-based-linux-distributions
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g brunch

# Install Sass
RUN apt-get install -y rubygems ruby2.1-dev && \
    gem install sass

# Clean up
RUN apt-get clean

ENV MIX_ENV=prod

ADD . .

WORKDIR /root/apps/site
RUN mix do deps.get, deps.compile && \
    npm install --only=production --no-optional && \
    brunch build --production && \
    mix phx.digest

WORKDIR /root
RUN mix release --verbose
