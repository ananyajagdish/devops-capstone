# https://docs.docker.com/reference/dockerfile/

# Base Image
FROM python:3.12-slim

RUN groupadd -r appuser && useradd -r -g appuser appuser
WORKDIR /app

# Copy the src folder from local to the container.
COPY app/src /app/src
COPY app/requirements.txt /app

# Install any Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

RUN chown -R appuser:appuser /app

USER appuser

EXPOSE 8080

# Define the command to run your application
CMD ["python", "src/app.py"]
