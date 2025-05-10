FROM python:3.10

WORKDIR /app
COPY . .

RUN pip install --no-cache-dir -r requirements.txt

# 👇 run.py should contain: `app = Flask(__name__)`
CMD exec gunicorn -b :8080 run:app
