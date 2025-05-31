FROM nginx:alpine

RUN rm -rf /usr/share/nginx/html/*

COPY app/   /usr/share/nginx/html/
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY .htpasswd /etc/nginx/.htpasswd

EXPOSE 80
