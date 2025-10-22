#!/bin/bash

# Скрипт восстановления текущего состояния серверов
# Используется для быстрого восстановления рабочей конфигурации

set -e

echo "🔄 Восстанавливаю текущее состояние серверов..."
echo ""

# Проверяем, что мы в правильной директории
if [ ! -f "backups/current-state/haproxy.cfg" ]; then
    echo "❌ Error: Run script from project root directory"
    exit 1
fi

# Восстанавливаем HAProxy конфигурацию
echo "1. Восстанавливаю HAProxy конфигурацию..."
gcloud compute ssh haproxy-prod --zone=europe-west1-b --command="
sudo cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.backup
sudo systemctl stop haproxy
"
gcloud compute scp backups/current-state/haproxy.cfg haproxy-prod:/tmp/haproxy.cfg --zone=europe-west1-b
gcloud compute ssh haproxy-prod --zone=europe-west1-b --command="
sudo mv /tmp/haproxy.cfg /etc/haproxy/haproxy.cfg
sudo chown haproxy:haproxy /etc/haproxy/haproxy.cfg
sudo systemctl start haproxy
"
echo "✅ HAProxy конфигурация восстановлена"

# Восстанавливаем Nginx конфигурации
echo "2. Восстанавливаю Nginx конфигурации..."
gcloud compute scp backups/current-state/web1-nginx.conf web1-prod:/tmp/nginx.conf --zone=europe-west1-b
gcloud compute ssh web1-prod --zone=europe-west1-b --command="
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup
sudo mv /tmp/nginx.conf /etc/nginx/nginx.conf
sudo nginx -t && sudo systemctl reload nginx
"

gcloud compute scp backups/current-state/web2-nginx.conf web2-prod:/tmp/nginx.conf --zone=europe-west1-b
gcloud compute ssh web2-prod --zone=europe-west1-b --command="
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup
sudo mv /tmp/nginx.conf /etc/nginx/nginx.conf
sudo nginx -t && sudo systemctl reload nginx
"
echo "✅ Nginx конфигурации восстановлены"

# Восстанавливаем SSL сертификаты
echo "3. Восстанавливаю SSL сертификаты..."
gcloud compute scp backups/current-state/balancer.svdevops.tech.pem haproxy-prod:/tmp/balancer.svdevops.tech.pem --zone=europe-west1-b
gcloud compute ssh haproxy-prod --zone=europe-west1-b --command="
sudo mv /tmp/balancer.svdevops.tech.pem /etc/haproxy/certs/balancer.svdevops.tech.pem
sudo chown haproxy:haproxy /etc/haproxy/certs/balancer.svdevops.tech.pem
sudo chmod 600 /etc/haproxy/certs/balancer.svdevops.tech.pem
sudo systemctl restart haproxy
"
echo "✅ SSL сертификаты восстановлены"

# Восстанавливаем контент
echo "4. Восстанавливаю контент web серверов..."
gcloud compute scp backups/current-state/web1-content.html web1-prod:/tmp/index.html --zone=europe-west1-b
gcloud compute ssh web1-prod --zone=europe-west1-b --command="sudo mv /tmp/index.html /var/www/html/index.html"

gcloud compute scp backups/current-state/web2-content.html web2-prod:/tmp/index.html --zone=europe-west1-b
gcloud compute ssh web2-prod --zone=europe-west1-b --command="sudo mv /tmp/index.html /var/www/html/index.html"
echo "✅ Контент восстановлен"

echo ""
echo "🎉 Состояние серверов успешно восстановлено!"
echo "🌐 Проверьте:"
echo "   https://balancer.svdevops.tech"
echo "   https://balancer.svdevops.tech/stats"
echo "   https://web1.svdevops.tech"
echo "   https://web2.svdevops.tech"
