FROM python:3.7-slim

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

RUN apt-get update && apt-get install -y \
    curl \
    python3-dev \
    python3-setuptools \
    git

COPY . /usr/src/app
RUN pip install -r requirements.txt

EXPOSE 5000
ENTRYPOINT ["python3", "src/app.py"]
