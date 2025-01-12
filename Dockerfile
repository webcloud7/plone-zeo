FROM python:3.9-slim-buster as base
FROM base as builder

ENV ZEO_VERSION=5.3.0

RUN mkdir /wheelhouse

RUN apt-get update \
    && buildDeps="build-essential" \
    && apt-get install -y --no-install-recommends $buildDeps\
    && rm -rf /var/lib/apt/lists/* /usr/share/doc\
    && pip install -U "pip"

RUN pip wheel "zeo==${ZEO_VERSION}" --wheel-dir=/wheelhouse

FROM base

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

EXPOSE 8100
VOLUME /data

CMD ["/app/start-zeo.sh"]
