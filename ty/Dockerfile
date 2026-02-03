FROM perl:5.38-slim

WORKDIR /app

# Install Mojolicious and dependencies
RUN cpanm --notest \
    Mojolicious \
    JSON::PP \
    Time::HiRes

# Run the application
CMD ["perl", "/app/tyrant-logger.pl", "daemon", "-l", "http://*:9393"]
