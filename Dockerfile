# Usamos la versión completa (no slim) para tener todas las herramientas de compilación
FROM ruby:3.4.2

# Instalar dependencias esenciales para PostgreSQL y Puppeteer (PDFs)
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libpq-dev \
    curl \
    git \
    unzip \
    libnss3 \
    libatk-bridge2.0-0 \
    libcups2 \
    libgbm1 \
    libasound2 \
    pango1.0-tools \
    libpangocairo-1.0-0 \
    libgtk-3-0

# Instalar Bun
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:$PATH"

# En Rails 8.1 la carpeta estándar es /rails
WORKDIR /rails

# Instalamos Rails 8.1 globalmente en la imagen
RUN gem install rails -v 8.1.0

EXPOSE 3000