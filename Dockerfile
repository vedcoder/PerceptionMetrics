FROM python:3.10-slim

# System deps for OpenCV, pycocotools (needs gcc for C extensions), Open3D
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc g++ libgl1 libglib2.0-0 libsm6 libxrender1 libxext6 curl \
    && rm -rf /var/lib/apt/lists/*

# Install Poetry
ENV POETRY_VERSION=2.3.2
RUN pip install --no-cache-dir poetry==$POETRY_VERSION

WORKDIR /app

# Copy dependency files first (cached layer)
COPY pyproject.toml poetry.lock ./

# Install dependencies (no dev/docs/test groups, no root package yet)
RUN poetry config virtualenvs.create false \
    && poetry install --no-root --without dev,docs,test --no-interaction

# Install PyTorch CPU-only (~200MB instead of 2GB GPU)
RUN pip install --no-cache-dir torch torchvision --index-url https://download.pytorch.org/whl/cpu

# Copy app code
COPY . .

# Install the package itself
RUN poetry install --only-root --no-interaction

EXPOSE 8501

HEALTHCHECK CMD curl --fail http://localhost:8501/_stcore/health || exit 1

ENTRYPOINT ["streamlit", "run", "app.py", "--server.address=0.0.0.0", "--server.port=8501"]
