# Stage 1: Build
FROM node:22.1.0 AS build

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci

# Set the API base URL for production build
ENV VITE_API_BASE_URL=/api

# Copy source files and build
COPY . .
RUN npm run build

# Stage 2: Serve with NGINX
FROM nginx:alpine

# Remove default nginx static assets
RUN rm -rf /usr/share/nginx/html/*

# Copy built frontend from previous stage
COPY --from=build /app/dist /usr/share/nginx/html

COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose HTTP port
EXPOSE 80

# Start NGINX
CMD ["nginx", "-g", "daemon off;"]


