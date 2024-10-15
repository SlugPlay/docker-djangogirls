FROM python:3.10-slim
RUN apt-get update &&\
    apt install -y libpq-dev \
         gcc \
         npm \
         gulp \
         gettext

COPY . ./app
WORKDIR /app

RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

RUN pip install --upgrade pip &&\
    pip install pip-tools &&\
    pip-sync &&\
    npm install &&\
    gulp local

ENTRYPOINT ["/app/rootfs/entrypoint.sh"]

