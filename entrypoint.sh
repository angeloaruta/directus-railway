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
if [ -f "${DIRECTUS_TEMPLATE_PATH}/src/schema/snapshot.json" ]; then
    echo "Applying template schema from snapshot.json..."
    npx directus schema apply "${DIRECTUS_TEMPLATE_PATH}/src/schema/snapshot.json" --yes
else
    echo "Warning: Schema file not found at ${DIRECTUS_TEMPLATE_PATH}/src/schema/snapshot.json"
    echo "Available files in schema directory:"
    ls -la ${DIRECTUS_TEMPLATE_PATH}/src/schema/
fi

# Import template data if directory exists
if [ -d "${DIRECTUS_TEMPLATE_PATH}/src/content" ]; then
    echo "Importing template data..."
    for file in ${DIRECTUS_TEMPLATE_PATH}/src/content/*.json; do
        if [ -f "$file" ]; then
            collection=$(basename "$file" .json)
            echo "Importing data for collection: $collection"
            npx directus import "$collection" "$file" --format=json
        fi
    done
else
    echo "Warning: Content directory not found"
fi

# Import roles and permissions
if [ -f "${DIRECTUS_TEMPLATE_PATH}/src/roles.json" ]; then
    echo "Importing roles..."
    npx directus roles import "${DIRECTUS_TEMPLATE_PATH}/src/roles.json"
fi

if [ -f "${DIRECTUS_TEMPLATE_PATH}/src/permissions.json" ]; then
    echo "Importing permissions..."
    npx directus permissions import "${DIRECTUS_TEMPLATE_PATH}/src/permissions.json"
fi

# Import presets and settings
if [ -f "${DIRECTUS_TEMPLATE_PATH}/src/presets.json" ]; then
    echo "Importing presets..."
    npx directus presets import "${DIRECTUS_TEMPLATE_PATH}/src/presets.json"
fi

if [ -f "${DIRECTUS_TEMPLATE_PATH}/src/settings.json" ]; then
    echo "Importing settings..."
    npx directus settings import "${DIRECTUS_TEMPLATE_PATH}/src/settings.json"
fi

# Start Directus
echo "Starting Directus..."
node cli.js bootstrap && pm2-runtime start ecosystem.config.cjs