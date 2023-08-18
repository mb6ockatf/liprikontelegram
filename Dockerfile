# syntax=docker/dockerfile:1
FROM debian:bookworm
# install lua and luarocks
RUN set -ex saved_apt_mark="$(apt-mark showmanual)" \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends ca-certificates curl gcc \
	libc6-dev make libreadline-dev dirmngr gnupg unzip \
	&& curl -fsSL -o \
		/tmp/lua.tar.gz "https://www.lua.org/ftp/lua-5.4.6.tar.gz" \
	&& cd /tmp \
	&& echo "7d5ea1b9cb6aa0b59ca3dde1c6adcb57ef83a1ba8e5432c0ecd06bf439b3ad88 *lua.tar.gz" \
		| sha256sum -c - \
	&& mkdir /tmp/lua \
	&& tar -xf /tmp/lua.tar.gz -C /tmp/lua --strip-components=1 \
	&& cd /tmp/lua \
	&& make linux \
	&& make install \
	&& curl -fsSL -o /tmp/luarocks.tar.gz \
		"https://luarocks.org/releases/luarocks-3.9.2.tar.gz" \
	&& curl -fsSL -o /tmp/luarocks.tar.gz.asc \
		"https://luarocks.org/releases/luarocks-3.9.2.tar.gz.asc" \
	&& cd /tmp \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& export GPG_KEYS="8460980B2B79786DE0C7FCC83FD8F43C2BB3C478" \
	&& (gpg --batch --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-keys "$GPG_KEYS" \
	|| gpg --batch --keyserver hkp://ipv4.pool.sks-keyservers.net:80 --recv-keys "$GPG_KEYS" \
	|| gpg --batch --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$GPG_KEYS" \
	|| gpg --batch --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys "$GPG_KEYS") \
	&& gpg --batch --verify luarocks.tar.gz.asc luarocks.tar.gz \
	&& rm -rf "$GNUPGHOME" \
	&& mkdir /tmp/luarocks \
	&& tar -xf /tmp/luarocks.tar.gz -C /tmp/luarocks --strip-components=1 \
	&& cd /tmp/luarocks \
	&& ./configure && make && make install \
	&& cd / \
	&& apt-mark auto '.*' > /dev/null \
	&& if [ -n "$saved_apt_mark" ]; then \
		apt-mark manual $saved_apt_mark; \
	fi \
	&& dpkg-query --show --showformat '${package}\n' | grep -P '^libreadline\d+$' | xargs apt-mark manual \
	&& apt-mark manual ca-certificates curl unzip \
	&& apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
	&& rm -rf /tmp/lua /tmp/lua.tar.gz \
	&& rm -rf /tmp/luarocks /tmp/luarocks.tar.gz \
	&& luarocks --version && lua -v
LABEL org.opencontainers.image.source="https://github.com/GUI/lua-docker" \
  org.opencontainers.image.licenses="MIT"
# install project dependences
RUN apt-get update && apt-get install -y --no-install-recommends git openssl \
	build-essential libssl-dev
RUN luarocks install luasec && luarocks install mfr \
	&& luarocks install argparse && luarocks install telegram-bot-lua
WORKDIR /app
COPY . .
CMD ["lua", "main.lua"]
