# Explicitly specify a Directus version to use on Railway
FROM directus/directus:11.8.0

USER root

# Set the environment variable for your timezone if needed
# RUN apk add --no-cache tzdata
# ENV TZ=America/New_York

RUN npm install -g pnpm --force

USER node

# Installing contributed/custom extensions through npm on Railway
RUN pnpm install @directus-labs/card-select-interfaces && pnpm install @directus-labs/simple-list-interface && \
 pnpm install @directus-labs/inline-repeater-interface && pnpm install @directus-labs/super-header-interface && \
 pnpm install directus-extension-wpslug-interface && pnpm install @directus-labs/experimental-m2a-interface && \
 pnpm install @directus-labs/seo-plugin && pnpm install @directus-labs/ai-image-generation-operation && \
 pnpm install @directus-labs/command-palette-module && pnpm install @directus-labs/ai-writer-operation && \
 pnpm install @directus-labs/liquidjs-operation

# Migrations and Directus schema update
RUN npx directus bootstrap

USER root

# Create and set permissions for data directory
RUN mkdir -p /directus/data && \
    mkdir -p /directus/data/uploads && \
    mkdir -p /directus/data/extensions && \
    mkdir -p /directus/data/templates && \
    mkdir -p /directus/data/migrations && \
    mkdir -p /directus/data/snapshots && \
    mkdir -p /directus/data/template && \
    chown -R node:node /directus/data && \
    chmod -R 755 /directus/data

# Copying the extensions, templates, migrations, and snapshots to the Directus container
COPY --chown=node:node ./extensions /directus/data/extensions
COPY --chown=node:node ./templates /directus/data/templates
COPY --chown=node:node ./migrations /directus/data/migrations
COPY --chown=node:node ./snapshots /directus/data/snapshots
COPY --chown=node:node ./template /directus/data/template
COPY --chown=node:node ./config.cjs /directus/data/config.cjs           

# Custom entrypoint script to run Directus on Railway for migrations, snapshots, and extensions
COPY entrypoint.sh /directus/entrypoint.sh
WORKDIR /directus
RUN chmod +x ./entrypoint.sh && \
    chown node:node ./entrypoint.sh

USER node
ENTRYPOINT ["./entrypoint.sh"]