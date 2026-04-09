# Small, official Python base image
FROM python:3.12-slim

# Work inside /app in the container
WORKDIR /app

# Copy dependency list first (better Docker caching)
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the API code
COPY . .

# Container will listen on 8000
EXPOSE 8000

# Start the API server
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]