# Local dev image. Relies on docker-compose's bind mount over /app for
# live code + hot reload, and on a named volume over /app/node_modules
# specifically (see root docker-compose.yml) - without that, the host's
# own node_modules (npm install run directly on the host, glibc) would
# shadow this image's Alpine/musl install at container start, breaking
# Next's natively-compiled SWC binary. Same reasoning as LisangaConnect's
# frontend/Dockerfile comment for its own (Vite) native binding.
FROM node:20-alpine

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm install

COPY . .

EXPOSE 3333

CMD ["npm", "run", "dev", "--", "-p", "3333", "-H", "0.0.0.0"]
