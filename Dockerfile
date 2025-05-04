# Base image
FROM python:3.12.3-slim-bookworm

#Working directory
WORKDIR /app

# Copy dependency files
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy app files
COPY . .

# Set default command
CMD [ "python", "CLI/main.py" ]