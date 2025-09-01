FROM python:3.10.13-slim

WORKDIR /app
COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt
COPY . .

ENV PORT=3000
EXPOSE 3000

CMD ["python", "app.py"]
