FROM ruby:3.4.2-slim-bookworm
ARG VERSION=$VERSION
RUN addgroup app --gid 10000 && adduser app --home /app --uid 10000 --ingroup app && apt -y update && apt -y install build-essential bash unzip vim libaio1 libaio-dev libyaml-dev && apt -y clean
USER app:app
WORKDIR /app

COPY Gemfile ./

COPY config.ru .
COPY config config
COPY lib lib
COPY app app
COPY public public
COPY run.sh run.sh

USER root
RUN bundle install
USER app:app

EXPOSE 9292
ENV LANG=C.UTF-8
ENV TZ="Europe/Brussels"

CMD ["/app/run.sh"]

#Metadata
LABEL org.opencontainers.image.vendor="KULeuven/LIBIS" \
        org.opencontainers.image.url="https://www.libis.be" \
	    org.opencontainers.image.title="Cover service" \
	    org.opencontainers.image.version=$VERSION