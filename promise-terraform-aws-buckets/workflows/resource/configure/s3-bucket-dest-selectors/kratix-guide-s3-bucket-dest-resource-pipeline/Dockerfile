FROM python:3.12-slim

RUN apt-get update && apt-get install -y git yq

RUN python -m pip install git+https://github.com/syntasso/kratix-python.git

WORKDIR /app
ADD resources/* resources/
ADD scripts/* scripts/
RUN chmod +x scripts/*

ENTRYPOINT []