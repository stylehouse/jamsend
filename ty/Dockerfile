FROM perl:5.38-slim

WORKDIR /app

# Install Mojolicious and dependencies
RUN cpanm --notest \
    Mojolicious \
    JSON::PP \
    Time::HiRes

# Copy the application
COPY ty/tyrant-logger.pl /app/

# Make it executable
RUN chmod +x /app/tyrant-logger.pl

# Create logs directory
RUN mkdir -p /logs

# Expose port
EXPOSE 3000

# Run the application
CMD ["perl", "/app/tyrant-logger.pl", "daemon", "-l", "http://*:3000"]
