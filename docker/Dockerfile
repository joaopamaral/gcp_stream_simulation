FROM python:3.8-slim-buster

ENV APP_HOME /app
WORKDIR $APP_HOME

COPY requirements.txt requirements.txt
RUN pip3 install -r requirements.txt

COPY stream_simulate_service_account_key.json stream_simulate_service_account_key.json
ENV GOOGLE_APPLICATION_CREDENTIALS /app/stream_simulate_service_account_key.json

COPY src .

CMD [ "python3", "stream_simulate.py"]