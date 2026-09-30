# Imagem do site para o Railway. 1ª etapa: compila com o Node; 2ª: serve os
# arquivos prontos com o nginx (leve, sem Node rodando em produção).

FROM node:24-alpine AS construcao
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
# Endereço do back-end, embutido no site na hora do build (variável
# VITE_API_URL do serviço no Railway).
ARG VITE_API_URL
ENV VITE_API_URL=$VITE_API_URL
RUN npm run build

FROM nginx:1.29-alpine
# O Railway informa a porta em PORT; o nginx troca ${PORT} no modelo ao iniciar.
ENV PORT=8080
COPY nginx.conf.template /etc/nginx/templates/default.conf.template
COPY --from=construcao /app/dist /usr/share/nginx/html
EXPOSE 8080
