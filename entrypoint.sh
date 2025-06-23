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

# Import template data if directory exists
CONTENT_DIR="${DIRECTUS_TEMPLATE_PATH}/src/content"
if [ -d "$CONTENT_DIR" ]; then
    echo "Found content directory at $CONTENT_DIR"
    echo "Importing template data..."
    # Create a temporary directory for the combined schema
    TEMP_DIR=$(mktemp -d)
    cp "$SCHEMA_FILE" "$TEMP_DIR/combined_schema.json"
    
    # Process each JSON file in the content directory
    for file in "$CONTENT_DIR"/*.json; do
        if [ -f "$file" ]; then
            collection=$(basename "$file" .json)
            echo "Processing data for collection: $collection"
            # Use jq to merge the data into the schema
            jq --arg collection "$collection" \
               --slurpfile data "$file" \
               '.collections[$collection].data = $data[0]' \
               "$TEMP_DIR/combined_schema.json" > "$TEMP_DIR/temp.json" && \
            mv "$TEMP_DIR/temp.json" "$TEMP_DIR/combined_schema.json"
        fi
    done
    
    # Apply the combined schema
    echo "Applying combined schema with data..."
    npx directus schema apply "$TEMP_DIR/combined_schema.json" --yes
    
    # Cleanup
    rm -rf "$TEMP_DIR"
else
    echo "Warning: Content directory not found at $CONTENT_DIR"
fi

# Import roles and permissions
ROLES_FILE="${DIRECTUS_TEMPLATE_PATH}/src/roles.json"
PERMISSIONS_FILE="${DIRECTUS_TEMPLATE_PATH}/src/permissions.json"

# Create a temporary file for roles
echo "Setting up roles and permissions..."
cat > /tmp/roles.json << 'EOL'
{
  "version": 1,
  "directus": "11.8.0",
  "collections": [],
  "fields": [],
  "relations": [],
  "roles": []
}
EOL

# Merge roles into the temporary schema
if [ -f "$ROLES_FILE" ]; then
    echo "Found roles file at $ROLES_FILE"
    echo "Importing roles..."
    jq -s '.[0].roles = .[1] | .[0]' /tmp/roles.json "$ROLES_FILE" > /tmp/roles_merged.json
    npx directus schema apply /tmp/roles_merged.json --yes
fi

# Create a temporary file for permissions
cat > /tmp/permissions.json << 'EOL'
{
  "version": 1,
  "directus": "11.8.0",
  "collections": [],
  "fields": [],
  "relations": [],
  "permissions": []
}
EOL

# Merge permissions into the temporary schema
if [ -f "$PERMISSIONS_FILE" ]; then
    echo "Found permissions file at $PERMISSIONS_FILE"
    echo "Importing permissions..."
    jq -s '.[0].permissions = .[1] | .[0]' /tmp/permissions.json "$PERMISSIONS_FILE" > /tmp/permissions_merged.json
    npx directus schema apply /tmp/permissions_merged.json --yes
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