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

# Switch to root for file operations
USER root

# Copying the extensions, templates, migrations, and snapshots to the Directus container
COPY --chown=node:node ./extensions /directus/extensions
COPY --chown=node:node ./templates /directus/templates
COPY --chown=node:node ./migrations /directus/migrations
COPY --chown=node:node ./snapshots /directus/snapshots
COPY --chown=node:node ./template /directus/template
COPY --chown=node:node ./config.cjs /directus/config.cjs           

# Custom entrypoint script to run Directus on Railway for migrations, snapshots, and extensions
COPY --chown=node:node entrypoint.sh /directus/entrypoint.sh
WORKDIR /directus
RUN chmod +x /directus/entrypoint.sh && \
    chown node:node /directus/entrypoint.sh

USER node
CMD ["/bin/sh", "/directus/entrypoint.sh"]