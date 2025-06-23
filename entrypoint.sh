#!/bin/sh

echo "Starting Directus with template initialization..."

# Bootstrap Directus
npx directus bootstrap

# Apply template schema
echo "Applying template schema from ${DIRECTUS_TEMPLATE_PATH}/src/schema/snapshot.json..."
npx directus schema apply "${DIRECTUS_TEMPLATE_PATH}/src/schema/snapshot.json" --yes

# Import template data
echo "Importing template data from ${DIRECTUS_TEMPLATE_PATH}/src/content..."
for file in ${DIRECTUS_TEMPLATE_PATH}/src/content/*.json; do
  if [ -f "$file" ]; then
    collection=$(basename "$file" .json)
    echo "Importing data for collection: $collection"
    npx directus import "$collection" "$file" --format=json
  fi
done

# Import roles and permissions
echo "Importing roles and permissions..."
if [ -f "${DIRECTUS_TEMPLATE_PATH}/src/roles.json" ]; then
  npx directus roles import "${DIRECTUS_TEMPLATE_PATH}/src/roles.json"
fi
if [ -f "${DIRECTUS_TEMPLATE_PATH}/src/permissions.json" ]; then
  npx directus permissions import "${DIRECTUS_TEMPLATE_PATH}/src/permissions.json"
fi

# Import presets and settings
echo "Importing presets and settings..."
if [ -f "${DIRECTUS_TEMPLATE_PATH}/src/presets.json" ]; then
  npx directus presets import "${DIRECTUS_TEMPLATE_PATH}/src/presets.json"
fi
if [ -f "${DIRECTUS_TEMPLATE_PATH}/src/settings.json" ]; then
  npx directus settings import "${DIRECTUS_TEMPLATE_PATH}/src/settings.json"
fi

# Start Directus
echo "Starting Directus..."
node cli.js bootstrap && pm2-runtime start ecosystem.config.cjs