FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Download spaCy Dutch model
RUN python -m spacy download nl_core_news_lg

# Copy application code
COPY src/ ./src/
COPY .env.example .env

# Expose port
EXPOSE 8000

# Run application
CMD ["uvicorn", "src.api.context_service:app", "--host", "0.0.0.0", "--port", "8000"]
