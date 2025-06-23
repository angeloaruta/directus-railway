#!/bin/sh

echo "Starting Directus with template initialization..."

# Debug information
echo "Checking template directory structure..."
ls -la ${DIRECTUS_TEMPLATE_PATH}
echo "Checking template src directory..."
ls -la ${DIRECTUS_TEMPLATE_PATH}/src
echo "Checking schema directory..."
ls -la ${DIRECTUS_TEMPLATE_PATH}/src/schema

# Bootstrap Directus
npx directus bootstrap

# Apply template schema if exists
SCHEMA_FILE="${DIRECTUS_TEMPLATE_PATH}/src/schema/snapshot.json"
if [ -f "$SCHEMA_FILE" ]; then
    echo "Applying template schema from $SCHEMA_FILE..."
    npx directus schema apply "$SCHEMA_FILE" --yes
else
    echo "Warning: Schema file not found at $SCHEMA_FILE"
fi

# Import template data if directory exists
CONTENT_DIR="${DIRECTUS_TEMPLATE_PATH}/src/content"
if [ -d "$CONTENT_DIR" ]; then
    echo "Importing template data from $CONTENT_DIR..."
    for file in $CONTENT_DIR/*.json; do
        if [ -f "$file" ]; then
            collection=$(basename "$file" .json)
            echo "Importing data for collection: $collection"
            npx directus import "$collection" "$file" --format=json
        fi
    done
else
    echo "Warning: Content directory not found at $CONTENT_DIR"
fi

# Import roles and permissions
ROLES_FILE="${DIRECTUS_TEMPLATE_PATH}/src/roles.json"
PERMISSIONS_FILE="${DIRECTUS_TEMPLATE_PATH}/src/permissions.json"
if [ -f "$ROLES_FILE" ]; then
    echo "Importing roles from $ROLES_FILE..."
    npx directus roles import "$ROLES_FILE"
fi
if [ -f "$PERMISSIONS_FILE" ]; then
    echo "Importing permissions from $PERMISSIONS_FILE..."
    npx directus permissions import "$PERMISSIONS_FILE"
fi

# Import presets and settings
PRESETS_FILE="${DIRECTUS_TEMPLATE_PATH}/src/presets.json"
SETTINGS_FILE="${DIRECTUS_TEMPLATE_PATH}/src/settings.json"
if [ -f "$PRESETS_FILE" ]; then
    echo "Importing presets from $PRESETS_FILE..."
    npx directus presets import "$PRESETS_FILE"
fi
if [ -f "$SETTINGS_FILE" ]; then
    echo "Importing settings from $SETTINGS_FILE..."
    npx directus settings import "$SETTINGS_FILE"
fi

# Start Directus
echo "Starting Directus..."
node cli.js bootstrap && pm2-runtime start ecosystem.config.cjs