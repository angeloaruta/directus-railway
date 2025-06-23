# Explicitly specify a Directus version to use on Railway
FROM directus/directus:11.8.0

USER root

# Set the environment variable for your timezone if needed
# RUN apk add --no-cache tzdata
# ENV TZ=America/New_York

RUN npm install -g pnpm --force

# Create template directory to store initial files
RUN mkdir -p /directus/template

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

WORKDIR /directus

# Copy template files to template directory
COPY --chown=node:node ./template/package.json ./template/README.md /directus/template/
COPY --chown=node:node ./template/src/schema/snapshot.json /directus/template/src/schema/
COPY --chown=node:node ./template/src/content/*.json /directus/template/src/content/
COPY --chown=node:node ./template/src/assets/* /directus/template/src/assets/
COPY --chown=node:node ./template/src/*.json /directus/template/src/

# Copying other directories
COPY --chown=node:node ./extensions /directus/template/extensions
COPY --chown=node:node ./templates /directus/template/templates
COPY --chown=node:node ./migrations /directus/template/migrations
COPY --chown=node:node ./snapshots /directus/template/snapshots
COPY --chown=node:node ./config.cjs /directus/template/config.cjs           

USER root

# Custom entrypoint script to run Directus on Railway for migrations, snapshots, and extensions
COPY entrypoint.sh /directus/entrypoint.sh
RUN chmod +x /directus/entrypoint.sh

# Set environment variables for template
ENV DIRECTUS_TEMPLATE_PATH=/directus/data/template
ENV DIRECTUS_TEMPLATE_NAME=directus-template-cms

ENTRYPOINT ["./entrypoint.sh"]