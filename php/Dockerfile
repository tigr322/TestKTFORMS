# php/Dockerfile
FROM php:8.2-apache

# 1) Apache и базовые пакеты
RUN a2enmod rewrite
RUN apt-get update && apt-get install -y \
    gnupg2 ca-certificates curl apt-transport-https \
    unixodbc-dev \
 && rm -rf /var/lib/apt/lists/*

# 2) Подключаем репозиторий Microsoft (без apt-key!)
RUN set -eux; \
    mkdir -p /etc/apt/keyrings; \
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /etc/apt/keyrings/microsoft.gpg; \
    echo "deb [arch=amd64,arm64 signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/debian/12/prod bookworm main" \
      | tee /etc/apt/sources.list.d/microsoft-prod.list > /dev/null; \
    apt-get update; \
    ACCEPT_EULA=Y apt-get install -y msodbcsql18 mssql-tools18; \
    echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> /etc/bash.bashrc; \
    rm -rf /var/lib/apt/lists/*

# 3) PHP модули + драйверы SQL Server
RUN docker-php-ext-install pdo
RUN pecl install sqlsrv pdo_sqlsrv && docker-php-ext-enable sqlsrv pdo_sqlsrv

WORKDIR /var/www/html
