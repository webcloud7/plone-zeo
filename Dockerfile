FROM python:3.11-slim-buster as base
FROM base as builder

ENV ZEO_VERSION=5.4.1

RUN mkdir /wheelhouse

RUN apt-get update \
    && buildDeps="build-essential" \
    && apt-get install -y --no-install-recommends $buildDeps\
    && rm -rf /var/lib/apt/lists/* /usr/share/doc\
    && pip install -U "pip"

RUN pip wheel "zeo==${ZEO_VERSION}" --wheel-dir=/wheelhouse -c https://dist.plone.org/release/6.0.9/constraints.txt

FROM base


RUN apt-get update \
    && apt-get install -y rsync build-essential vim cron

LABEL maintainer="Plone Community <dev@plone.org>" \
      org.label-schema.name="plone-zeo" \
      org.label-schema.description="ZEO (ZODB) Server." \
      org.label-schema.vendor="Plone Foundation"

COPY --from=builder /wheelhouse /wheelhouse

RUN useradd --system -m -d /app -U -u 500 plone \
    && python -m venv /app \
    && /app/bin/pip install --force-reinstall --no-index --no-deps /wheelhouse/* \
    && find . \( -type f -a -name '*.pyc' -o -name '*.pyo' \) -exec rm -rf '{}' + \
    && mkdir -p /data /app/var \
    && chown -R plone:plone /app /data

WORKDIR /app
USER plone

COPY start-zeo.sh /app/start-zeo.sh
COPY etc /app/etc
COPY scripts /app/scripts

RUN echo "0 0 * * * /app/bin/python /app/scripts/pack.py" > /etc/cron.d/python-cron
RUN chmod 0644 /etc/cron.d/python-cron
RUN crontab /etc/cron.d/python-cron

EXPOSE 8100
VOLUME /data

CMD ["/app/start-zeo.sh"]
