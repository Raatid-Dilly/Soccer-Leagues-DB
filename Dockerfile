FROM python:3.9.7

WORKDIR /app
ENV PYTHONPATH=/app/code

COPY ./ /app/

RUN apt update
RUN pip install -r requirements.txt

#ENTRYPOINT [ "python3", "soccer_leagues.py" ]

