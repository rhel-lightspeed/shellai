FROM ubi9/ubi-minimal:latest

# Default python version
ARG PYTHON_VERSION=python3.12

# todo: this is overriden by the image ubi9/python-311, we hard coded WORKDIR below to /app-root
# makesure the default value of rag content is set according to APP_ROOT and then update the operator.
ARG APP_ROOT=/app-root

RUN microdnf install -y --nodocs --setopt=keepcache=0 --setopt=tsflags=nodocs \
    ${PYTHON_VERSION} ${PYTHON_VERSION}-devel ${PYTHON_VERSION}-pip

# PYTHONDONTWRITEBYTECODE 1 : disable the generation of .pyc
# PYTHONUNBUFFERED 1 : force the stdout and stderr streams to be unbuffered
# PYTHONCOERCECLOCALE 0, PYTHONUTF8 1 : skip legacy locales and use UTF-8 mode
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONCOERCECLOCALE=0 \
    PYTHONUTF8=1 \
    PYTHONIOENCODING=UTF-8 \
    LANG=en_US.UTF-8 \
    PIP_NO_CACHE_DIR=off

WORKDIR /${APP_ROOT}

COPY shellai ./shellai
COPY requirements.txt ./

RUN pip3.12 install --no-cache-dir -r requirements.txt

ENTRYPOINT ["/usr/bin/python3.12", "-m", "shellai"]

LABEL description="A simple wrapper to interact with RAG" \
    summary="A simple wrapper to interact with RAG" \
    com.redhat.component=rhel-lightspeed-shellai \
    name=shellai \
    vendor="Red Hat, Inc."

# no-root user is checked in Konflux
USER 1001
