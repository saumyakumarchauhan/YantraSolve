FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim

# 1. Hugging Face Spaces require user ID 1000
RUN groupadd --system --gid 1000 nonroot \
 && useradd --system --gid 1000 --uid 1000 --create-home nonroot

WORKDIR /app

# 2. Install required system dependencies for OpenCV and pyzbar
RUN apt-get update && apt-get install -y \
    libgl1 \
    libglib2.0-0 \
    libzbar0 \
    && rm -rf /var/lib/apt/lists/*

ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy
ENV UV_TOOL_BIN_DIR=/usr/local/bin
ENV PLAYWRIGHT_BROWSERS_PATH=0
# 3. Force the port to Hugging Face's default
ENV PORT=7860
EXPOSE 7860

ENV PATH="/app/.venv/bin:$PATH"

COPY pyproject.toml uv.lock /app/
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked --no-install-project --no-dev

COPY . /app

RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked --no-dev

# 4. Ensure EVERYTHING in /app is owned by user 1000 so the app can write temp/cache files
RUN chown -R nonroot:nonroot /app

USER nonroot

RUN python -m playwright install chromium --with-deps

# Start the app (main.py will automatically pick up the PORT=7860 env variable)
CMD ["uv", "run", "main.py"]
