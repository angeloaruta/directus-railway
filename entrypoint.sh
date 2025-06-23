#!/bin/sh

echo "Starting Directus with template initialization..."

# Debug information
echo "Current working directory: $(pwd)"

# Create necessary directories and set permissions after volume mount
echo "Setting up directories and permissions..."
mkdir -p /directus/data/uploads \
    /directus/data/extensions \
    /directus/data/templates \
    /directus/data/migrations \
    /directus/data/snapshots \
    /directus/data/template \
    /directus/data/template/src \
    /directus/data/template/src/schema \
    /directus/data/template/src/content \
    /directus/data/template/src/assets

# Set proper ownership and permissions
chown -R node:node /directus/data
chmod -R 755 /directus/data
chmod 775 /directus/data/uploads
chmod 755 /directus/data/extensions

# Copy template files if they don't exist
if [ ! -f "${DIRECTUS_TEMPLATE_PATH}/src/schema/snapshot.json" ]; then
    echo "Copying template files..."
    cp -r /directus/template/* /directus/data/template/ || echo "No template files to copy"
fi

# Bootstrap Directus
echo "Running Directus bootstrap..."
npx directus bootstrap

# Apply template schema if exists
SCHEMA_FILE="${DIRECTUS_TEMPLATE_PATH}/src/schema/snapshot.json"
if [ -f "$SCHEMA_FILE" ]; then
    echo "Found schema file at $SCHEMA_FILE"
    echo "Applying template schema..."
    npx directus schema apply "$SCHEMA_FILE" --yes
else
    echo "Warning: Schema file not found at $SCHEMA_FILE"
    echo "Searching for schema file..."
    find /directus/data -name "snapshot.json"
fi

# Final permission check
echo "Performing final permission check..."
chown -R node:node /directus/data
chmod -R 755 /directus/data
chmod 775 /directus/data/uploads
chmod 755 /directus/data/extensions

# Start Directus
echo "Starting Directus..."
exec node cli.js bootstrap && pm2-runtime start ecosystem.config.cjs