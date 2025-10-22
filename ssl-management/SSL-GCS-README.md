# 🔐 SSL Certificate Management with Google Cloud Storage

## 📋 Обзор

Система централизованного управления SSL сертификатами Let's Encrypt через Google Cloud Storage (GCS). Сертификаты экспортируются в GCS bucket и могут быть использованы для создания новых образов или восстановления на серверах.

## 🪣 GCS Bucket

- **Название:** `ssl-certs-{PROJECT_ID}`
- **Структура:**
  ```
  gs://ssl-certs-{PROJECT_ID}/
  ├── haproxy/
  │   └── balancer.svdevops.tech.pem
  ├── web1/
  │   ├── web1.svdevops.tech.pem
  │   └── web1.svdevops.tech.key
  ├── web2/
  │   ├── web2.svdevops.tech.pem
  │   └── web2.svdevops.tech.key
  └── certificate-index.txt
  ```

## 🚀 Скрипты

### **1. SSL Manager (рекомендуется)**
```bash
./ssl-manager.sh
```
Интерактивное меню для управления сертификатами:
- Экспорт сертификатов в GCS
- Импорт сертификатов из GCS
- Создание образов с сертификатами
- Просмотр и тестирование сертификатов

### **2. Экспорт сертификатов в GCS**
```bash
./export-certs-to-gcs.sh
```
- Экспортирует все Let's Encrypt сертификаты с серверов
- Создает GCS bucket если не существует
- Загружает сертификаты в структурированном виде
- Создает индекс сертификатов

### **3. Импорт сертификатов из GCS**
```bash
./import-certs-from-gcs.sh
```
- Загружает сертификаты из GCS bucket
- Применяет их на текущие серверы
- Перезапускает сервисы
- Тестирует работоспособность

### **4. Создание образов с сертификатами из GCS**
```bash
./create-images-with-gcs-certs.sh
```
- Импортирует сертификаты из GCS
- Применяет правильные конфигурации
- Создает новые образы v4 с сертификатами
- Запускает серверы

## 🔄 Workflow

### **Экспорт сертификатов:**
1. Запустите `./ssl-manager.sh`
2. Выберите "1. Export certificates to GCS bucket"
3. Сертификаты будут экспортированы в GCS

### **Создание образов с сертификатами:**
1. Убедитесь, что сертификаты экспортированы в GCS
2. Запустите `./create-images-with-gcs-certs.sh`
3. Обновите Terraform для использования образов v4
4. Протестируйте деплой

### **Восстановление сертификатов:**
1. Запустите `./ssl-manager.sh`
2. Выберите "2. Import certificates from GCS bucket"
3. Сертификаты будут восстановлены на серверах

## 📋 Команды GCS

### **Просмотр сертификатов:**
```bash
gsutil ls -la gs://ssl-certs-{PROJECT_ID}/
```

### **Загрузка конкретного сертификата:**
```bash
gsutil cp gs://ssl-certs-{PROJECT_ID}/haproxy/balancer.svdevops.tech.pem ./haproxy-cert.pem
gsutil cp gs://ssl-certs-{PROJECT_ID}/web1/web1.svdevops.tech.pem ./web1-cert.pem
gsutil cp gs://ssl-certs-{PROJECT_ID}/web2/web2.svdevops.tech.pem ./web2-cert.pem
```

### **Загрузка всех сертификатов:**
```bash
gsutil -m cp -r gs://ssl-certs-{PROJECT_ID}/* ./ssl-certs-backup/
```

## 🎯 Преимущества

### **✅ Централизованное хранение:**
- Все сертификаты в одном месте
- Легко создавать резервные копии
- Простое восстановление

### **✅ Автоматизация:**
- Автоматический экспорт/импорт
- Создание образов с сертификатами
- Тестирование работоспособности

### **✅ Безопасность:**
- Сертификаты хранятся в GCS
- Контролируемый доступ
- Версионирование

## 🔧 Интеграция с Terraform

### **Обновление Terraform для образов v4:**
```hcl
# haproxy.tf
boot_disk {
  initialize_params {
    image = "haproxy-prod-image-v4"  # With GCS certificates
  }
}

# web-servers.tf
boot_disk {
  initialize_params {
    image = "web1-prod-image-v4"  # With GCS certificates
  }
}
```

## 🆘 Устранение проблем

### **Если GCS bucket не найден:**
```bash
# Создать bucket вручную
gsutil mb gs://ssl-certs-{PROJECT_ID}
```

### **Если сертификаты не загружаются:**
```bash
# Проверить права доступа
gsutil iam get gs://ssl-certs-{PROJECT_ID}
```

### **Если сертификаты не применяются:**
```bash
# Проверить логи серверов
gcloud compute ssh haproxy-prod --zone=europe-west1-b --command="sudo journalctl -u haproxy -f"
```

## 💡 Рекомендации

1. **Регулярно экспортируйте сертификаты** в GCS
2. **Создавайте образы с сертификатами** для быстрого деплоя
3. **Тестируйте восстановление** сертификатов
4. **Мониторьте срок действия** сертификатов
5. **Используйте SSL Manager** для удобного управления
