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

echo "Listing /directus/data directory:"
ls -la /directus/data

# Copy template files if they don't exist
if [ ! -f "${DIRECTUS_TEMPLATE_PATH}/src/schema/snapshot.json" ]; then
    echo "Copying template files..."
    cp -r /directus/template/* /directus/data/template/ || echo "No template files to copy"
fi

echo "Listing template directory:"
ls -la ${DIRECTUS_TEMPLATE_PATH} || echo "Template directory not found"
echo "Listing template src directory:"
ls -la ${DIRECTUS_TEMPLATE_PATH}/src || echo "Template src directory not found"
echo "Listing schema directory:"
ls -la ${DIRECTUS_TEMPLATE_PATH}/src/schema || echo "Schema directory not found"

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

# Import template data if directory exists using schema snapshot
CONTENT_DIR="${DIRECTUS_TEMPLATE_PATH}/src/content"
if [ -d "$CONTENT_DIR" ]; then
    echo "Found content directory at $CONTENT_DIR"
    echo "Importing template data..."
    # Use schema snapshot to import data
    npx directus schema snapshot "$SCHEMA_FILE" --yes
else
    echo "Warning: Content directory not found at $CONTENT_DIR"
fi

# Import roles and permissions
ROLES_FILE="${DIRECTUS_TEMPLATE_PATH}/src/roles.json"
PERMISSIONS_FILE="${DIRECTUS_TEMPLATE_PATH}/src/permissions.json"

if [ -f "$ROLES_FILE" ]; then
    echo "Found roles file at $ROLES_FILE"
    echo "Importing roles..."
    npx directus schema apply "$ROLES_FILE" --yes
else
    echo "Warning: Roles file not found at $ROLES_FILE"
fi

if [ -f "$PERMISSIONS_FILE" ]; then
    echo "Found permissions file at $PERMISSIONS_FILE"
    echo "Importing permissions..."
    npx directus schema apply "$PERMISSIONS_FILE" --yes
else
    echo "Warning: Permissions file not found at $PERMISSIONS_FILE"
fi

# Import presets and settings
PRESETS_FILE="${DIRECTUS_TEMPLATE_PATH}/src/presets.json"
SETTINGS_FILE="${DIRECTUS_TEMPLATE_PATH}/src/settings.json"

if [ -f "$PRESETS_FILE" ]; then
    echo "Found presets file at $PRESETS_FILE"
    echo "Importing presets..."
    npx directus schema apply "$PRESETS_FILE" --yes
else
    echo "Warning: Presets file not found at $PRESETS_FILE"
fi

if [ -f "$SETTINGS_FILE" ]; then
    echo "Found settings file at $SETTINGS_FILE"
    echo "Importing settings..."
    npx directus schema apply "$SETTINGS_FILE" --yes
else
    echo "Warning: Settings file not found at $SETTINGS_FILE"
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