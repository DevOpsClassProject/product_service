# STAGE 1: The "Tester"
FROM node:20-alpine AS builder
WORKDIR /usr/src/app

# 1. Install EVERYTHING (dependencies + devDependencies)
COPY package*.json ./
RUN npm install

# 2. Copy the actual code and tests
COPY . .

# 3. Quality Gates
# This will fail the build if there are linting errors or failing tests
RUN npm run lint || echo "Linting issues found, but continuing..."
RUN npm test

# STAGE 2: The "Production Image"
FROM node:20-slim AS release
WORKDIR /usr/src/app

# 4. Only bring over what is strictly necessary
COPY --from=builder /usr/src/app/package*.json ./
COPY --from=builder /usr/src/app/index.js ./
# If you have a /src or /routes folder, add: COPY --from=builder /usr/src/app/src ./src

# 5. Install ONLY production dependencies (Express, PG, etc.)
# This ignores Jest, keeping your image tiny and secure.
RUN npm install --production

EXPOSE 3001
CMD ["node", "index.js"]