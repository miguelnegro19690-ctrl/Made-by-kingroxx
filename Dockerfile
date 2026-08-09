# Agnes Video Generator — Container Build
FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

# Install ffmpeg via imageio-ffmpeg (static binary)
ARG PIP_INDEX_URL=
RUN if [ -n "$PIP_INDEX_URL" ]; then \
        pip config set global.index-url "$PIP_INDEX_URL"; \
    fi \
    && pip install --no-cache-dir --default-timeout=600 imageio-ffmpeg \
    && if [ -n "$PIP_INDEX_URL" ]; then \
        pip config unset global.index-url; \
    fi

# Link ffmpeg binary to PATH
RUN FFMPEG_BIN=$(python -c "import imageio_ffmpeg, os; print(os.path.join(os.path.dirname(imageio_ffmpeg.__file__), 'binaries', os.listdir(os.path.join(os.path.dirname(imageio_ffmpeg.__file__), 'binaries'))[0]))") \
    && ln -sf "$FFMPEG_BIN" /usr/local/bin/ffmpeg \
    && FFMPEG_EXE=$(python -c "import imageio_ffmpeg; print(imageio_ffmpeg.get_ffmpeg_exe())") \
    && ln -sf "$FFMPEG_EXE" /usr/local/bin/ffmpeg \
    && ffmpeg -version | head -1

# Install Python dependencies
COPY requirements.txt .
RUN if [ -n "$PIP_INDEX_URL" ]; then \
        pip config set global.index-url "$PIP_INDEX_URL"; \
    fi \
    && pip install --no-cache-dir --default-timeout=600 -r requirements.txt \
    && if [ -n "$PIP_INDEX_URL" ]; then \
        pip config unset global.index-url; \
    fi

# Copy application code
COPY . .

EXPOSE 8765

# Declare persistent volumes (optional – comment out if you don't need them)
VOLUME ["/app/.working_dir", "/app/.agnes_config"]

CMD ["python", "server.py"]
