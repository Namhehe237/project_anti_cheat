# Use Python 3.11 slim as base image
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Prevent Python from writing pyc files and buffer output
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1


RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        # OpenCV dependencies
        libgl1 \
        libglib2.0-0 \
        libsm6 \
        libxext6 \
        libxrender1 \
        # MediaPipe dependencies
        libgomp1 \
        libgstreamer1.0-0 \
        libgstreamer-plugins-base1.0-0 \
        # Audio processing dependencies
        portaudio19-dev \
        libasound2 \
        libsndfile1 \
        # Protobuf for MediaPipe
        libprotobuf-dev \
        protobuf-compiler \
        # Build tools for compiling Python packages
        build-essential \
        gcc \
        g++ \
        # Utility for healthchecks
        wget \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copy and install Python dependencies
COPY requirements.txt .

# Install dependencies in specific order to fix MediaPipe issues
RUN pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install --no-cache-dir protobuf==3.20.3 && \
    pip install --no-cache-dir numpy>=1.24.0 && \
    pip install --no-cache-dir opencv-python-headless>=4.8.0 && \
    pip install --no-cache-dir mediapipe==0.10.9 && \
    pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app/ ./app/

# Copy run script if exists
COPY run.sh ./
RUN chmod +x run.sh

# Expose the application port
EXPOSE 8081

# Healthcheck using wget (lightweight alternative to curl/requests)
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8081/health || exit 1

# Run the FastAPI application with uvicorn
CMD ["python", "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8081"]

