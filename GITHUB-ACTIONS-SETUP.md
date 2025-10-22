# 🔐 GitHub Actions Setup Guide

## Required GitHub Secrets

Для работы GitHub Actions необходимо настроить следующие секреты в репозитории:

### 1. GCP_SA_KEY
Service Account ключ для доступа к Google Cloud Platform.

**Как получить:**
1. Перейдите в [Google Cloud Console](https://console.cloud.google.com/)
2. Выберите ваш проект: `fair-plasma-475719-g7`
3. Перейдите в **IAM & Admin** → **Service Accounts**
4. Создайте новый Service Account или используйте существующий
5. Добавьте следующие роли:
   - `Compute Instance Admin`
   - `Compute Network Admin`
   - `DNS Administrator`
   - `Storage Admin`
   - `Service Account User`
6. Создайте ключ: **Actions** → **Manage Keys** → **Add Key** → **Create New Key** → **JSON**
7. Скопируйте содержимое JSON файла

**Как добавить в GitHub:**
1. Перейдите в ваш репозиторий на GitHub
2. **Settings** → **Secrets and variables** → **Actions**
3. **New repository secret**
4. Name: `GCP_SA_KEY`
5. Value: вставьте содержимое JSON файла **как есть** (без base64 кодирования)

### 2. GCP_PROJECT_ID
ID вашего Google Cloud проекта.

**Значение:** `fair-plasma-475719-g7`

**Как добавить в GitHub:**
1. **Settings** → **Secrets and variables** → **Actions**
2. **New repository secret**
3. Name: `GCP_PROJECT_ID`
4. Value: `fair-plasma-475719-g7`

## 🚀 Как работает workflow

### Триггеры:
- **Push** на ветки `main` или `develop`
- **Manual trigger** через GitHub Actions UI

### Что происходит:
1. **Checkout** кода из репозитория
2. **Setup** Google Cloud CLI и Terraform
3. **Authenticate** с помощью Service Account
4. **Initialize** и **Plan** Terraform
5. **Apply** инфраструктуры
6. **Apply** контента из `web-apps/`
7. **Test** развертывания
8. **Display** информации о результатах

### Результат:
- Инфраструктура развернута на Google Cloud
- Контент из `web-apps/` применен на все серверы
- Load balancing протестирован
- Показаны URL для доступа

## 🔧 Настройка Service Account

Если нужно создать новый Service Account:

```bash
# Создать Service Account
gcloud iam service-accounts create github-actions \
    --display-name="GitHub Actions" \
    --description="Service account for GitHub Actions"

# Добавить роли
gcloud projects add-iam-policy-binding fair-plasma-475719-g7 \
    --member="serviceAccount:github-actions@fair-plasma-475719-g7.iam.gserviceaccount.com" \
    --role="roles/compute.instanceAdmin"

gcloud projects add-iam-policy-binding fair-plasma-475719-g7 \
    --member="serviceAccount:github-actions@fair-plasma-475719-g7.iam.gserviceaccount.com" \
    --role="roles/compute.networkAdmin"

gcloud projects add-iam-policy-binding fair-plasma-475719-g7 \
    --member="serviceAccount:github-actions@fair-plasma-475719-g7.iam.gserviceaccount.com" \
    --role="roles/dns.admin"

gcloud projects add-iam-policy-binding fair-plasma-475719-g7 \
    --member="serviceAccount:github-actions@fair-plasma-475719-g7.iam.gserviceaccount.com" \
    --role="roles/storage.admin"

gcloud projects add-iam-policy-binding fair-plasma-475719-g7 \
    --member="serviceAccount:github-actions@fair-plasma-475719-g7.iam.gserviceaccount.com" \
    --role="roles/compute.securityAdmin"

# Создать ключ
gcloud iam service-accounts keys create github-actions-key.json \
    --iam-account=github-actions@fair-plasma-475719-g7.iam.gserviceaccount.com
```

## 🧪 Тестирование

После настройки секретов:

1. **Push** изменения в ветку `main` или `develop`
2. Перейдите в **Actions** вкладку на GitHub
3. Увидите запуск workflow "Deploy Infrastructure"
4. Следите за логами выполнения
5. После успешного завершения инфраструктура будет развернута

## 🚨 Troubleshooting

### Ошибка аутентификации:
- Проверьте правильность `GCP_SA_KEY`
- Убедитесь, что Service Account имеет необходимые роли
- **Важно**: Добавляйте JSON ключ как есть, без base64 кодирования

### Ошибка "base64: invalid input":
- Удалите существующий `GCP_SA_KEY` secret
- Создайте новый secret с содержимым JSON файла **как есть**
- Не кодируйте JSON в base64 перед добавлением в GitHub

### Ошибка Terraform:
- Проверьте, что проект ID правильный
- Убедитесь, что APIs включены в Google Cloud
