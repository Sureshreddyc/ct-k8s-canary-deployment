FROM python:3.7.2-slim

# Set the working directory
WORKDIR /usr/src/app

# Install dependencies
RUN apt-get -qqy update && apt-get install -qqy \
    curl \
    python-dev \
    python-setuptools \
    git

# Copy the application files
COPY . /usr/src/app

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Expose the application port
EXPOSE 5000

# Define the entry point for the container
ENTRYPOINT ["python3", "src/app.py"]
