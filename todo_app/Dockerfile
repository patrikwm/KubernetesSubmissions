FROM python:3.10.13-slim

WORKDIR /app
COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt
COPY . .

ENV PORT=8080
EXPOSE 8080

CMD ["python", "app.py"]
