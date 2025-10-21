#!/bin/bash

# 📊 GitHub Actions Monitor Script
# Мониторинг статуса GitHub Actions без браузера

set -e

echo "📊 GitHub Actions Monitor"
echo "========================"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для проверки статуса
check_workflow_status() {
    local workflow_name="$1"
    local status=$(curl -s "https://api.github.com/repos/vlad-ultra/-Google-Cloud-Infrastructure-Automation/actions/runs" | \
        grep -A10 -B2 "\"name\": \"$workflow_name\"" | \
        grep -E '"status"|"conclusion"' | head -2)
    
    echo "$status"
}

# Функция для получения деталей workflow
get_workflow_details() {
    local run_id="$1"
    echo "🔍 Детали workflow run $run_id:"
    curl -s "https://api.github.com/repos/vlad-ultra/-Google-Cloud-Infrastructure-Automation/actions/runs/$run_id" | \
        grep -E '"name"|"status"|"conclusion"|"created_at"|"html_url"' | head -10
}

# Основная функция мониторинга
monitor_workflows() {
    echo "🔍 Проверяю статус всех workflow..."
    echo ""
    
    # Получаем последние workflow runs
    local response=$(curl -s "https://api.github.com/repos/vlad-ultra/-Google-Cloud-Infrastructure-Automation/actions/runs")
    
    echo "📋 Последние workflow runs:"
    echo "=========================="
    
    # Парсим и выводим информацию
    echo "$response" | jq -r '.workflow_runs[] | "\(.name) - \(.status) - \(.conclusion // "running") - \(.created_at)"' 2>/dev/null || {
        echo "❌ Ошибка парсинга JSON. Устанавливаю jq..."
        if command -v brew &> /dev/null; then
            brew install jq
        else
            echo "⚠️ Установите jq для лучшего отображения"
        fi
    }
    
    echo ""
    echo "🔗 Ссылки на workflow runs:"
    echo "=========================="
    echo "$response" | jq -r '.workflow_runs[] | "\(.name): \(.html_url)"' 2>/dev/null || {
        echo "⚠️ Для детального просмотра перейдите в GitHub Actions"
    }
}

# Функция для проверки конкретного workflow
check_specific_workflow() {
    local workflow_name="$1"
    echo "🔍 Проверяю $workflow_name..."
    
    local status=$(curl -s "https://api.github.com/repos/vlad-ultra/-Google-Cloud-Infrastructure-Automation/actions/runs" | \
        jq -r ".workflow_runs[] | select(.name == \"$workflow_name\") | .status" | head -1)
    
    local conclusion=$(curl -s "https://api.github.com/repos/vlad-ultra/-Google-Cloud-Infrastructure-Automation/actions/runs" | \
        jq -r ".workflow_runs[] | select(.name == \"$workflow_name\") | .conclusion" | head -1)
    
    case "$status" in
        "queued")
            echo -e "${YELLOW}⏳ $workflow_name: В очереди${NC}"
            ;;
        "in_progress")
            echo -e "${BLUE}🔄 $workflow_name: Выполняется${NC}"
            ;;
        "completed")
            if [ "$conclusion" = "success" ]; then
                echo -e "${GREEN}✅ $workflow_name: Успешно завершен${NC}"
            else
                echo -e "${RED}❌ $workflow_name: Завершен с ошибкой${NC}"
            fi
            ;;
        *)
            echo -e "${YELLOW}⚠️ $workflow_name: Статус неизвестен ($status)${NC}"
            ;;
    esac
}

# Главное меню
case "${1:-monitor}" in
    "monitor")
        monitor_workflows
        ;;
    "deploy")
        check_specific_workflow "🚀 Auto Deploy Infrastructure"
        ;;
    "update")
        check_specific_workflow "🔄 Update Content"
        ;;
    "monitor-workflow")
        check_specific_workflow "📊 Monitor Infrastructure"
        ;;
    "help")
        echo "📋 Использование:"
        echo "  ./monitor-github-actions.sh [команда]"
        echo ""
        echo "Команды:"
        echo "  monitor          - Показать все workflow runs"
        echo "  deploy           - Проверить deploy workflow"
        echo "  update           - Проверить update content workflow"
        echo "  monitor-workflow - Проверить monitor workflow"
        echo "  help             - Показать эту справку"
        ;;
    *)
        echo "❌ Неизвестная команда: $1"
        echo "Используйте: ./monitor-github-actions.sh help"
        ;;
esac

echo ""
echo "🔗 GitHub Actions: https://github.com/vlad-ultra/-Google-Cloud-Infrastructure-Automation/actions"
