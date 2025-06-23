#!/bin/sh

echo "Starting Directus with template initialization..."

# Debug information
echo "Current working directory: $(pwd)"
echo "Listing /directus/data directory:"
ls -la /directus/data
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

# Import template data if directory exists
CONTENT_DIR="${DIRECTUS_TEMPLATE_PATH}/src/content"
if [ -d "$CONTENT_DIR" ]; then
    echo "Found content directory at $CONTENT_DIR"
    echo "Importing template data..."
    for file in "$CONTENT_DIR"/*.json; do
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
    echo "Found roles file at $ROLES_FILE"
    echo "Importing roles..."
    npx directus roles import "$ROLES_FILE"
else
    echo "Warning: Roles file not found at $ROLES_FILE"
fi

if [ -f "$PERMISSIONS_FILE" ]; then
    echo "Found permissions file at $PERMISSIONS_FILE"
    echo "Importing permissions..."
    npx directus permissions import "$PERMISSIONS_FILE"
else
    echo "Warning: Permissions file not found at $PERMISSIONS_FILE"
fi

# Import presets and settings
PRESETS_FILE="${DIRECTUS_TEMPLATE_PATH}/src/presets.json"
SETTINGS_FILE="${DIRECTUS_TEMPLATE_PATH}/src/settings.json"

if [ -f "$PRESETS_FILE" ]; then
    echo "Found presets file at $PRESETS_FILE"
    echo "Importing presets..."
    npx directus presets import "$PRESETS_FILE"
else
    echo "Warning: Presets file not found at $PRESETS_FILE"
fi

if [ -f "$SETTINGS_FILE" ]; then
    echo "Found settings file at $SETTINGS_FILE"
    echo "Importing settings..."
    npx directus settings import "$SETTINGS_FILE"
else
    echo "Warning: Settings file not found at $SETTINGS_FILE"
fi

# Start Directus
echo "Starting Directus..."
node cli.js bootstrap && pm2-runtime start ecosystem.config.cjs