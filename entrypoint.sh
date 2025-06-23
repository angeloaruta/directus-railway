#!/bin/sh
set -e

echo "Starting Directus initialization..."

# Bootstrap Directus
echo "Running Directus bootstrap..."
npx directus bootstrap

# Uncomment the following lines if you want to sync the snapshot
# echo "Applying schema snapshot..."
# npx directus schema apply --yes ./snapshots/snapshot.yaml

echo "Starting Directus with PM2..."
node cli.js bootstrap && pm2-runtime start ecosystem.config.cjs