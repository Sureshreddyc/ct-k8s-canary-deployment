FROM python:3.7-slim-buster

# Set the working directory
WORKDIR /usr/src/app

# Install dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    python3-dev \
    python3-setuptools \
    git && \
    rm -rf /var/lib/apt/lists/*

# Copy the application files
COPY . /usr/src/app

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Expose the application port
EXPOSE 5000

# Define the default command
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]
