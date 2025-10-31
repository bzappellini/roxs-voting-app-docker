#!/bin/bash

# Script de verificación de la aplicación ROXS Voting App
# Este script verifica que todos los servicios estén funcionando correctamente

set -e

echo "🔍 Verificando servicios de ROXS Voting App..."
echo ""

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para verificar un servicio
check_service() {
    local service_name=$1
    local url=$2
    local expected_status=${3:-200}
    
    echo -n "Verificando $service_name... "
    
    if response=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null); then
        if [ "$response" -eq "$expected_status" ]; then
            echo -e "${GREEN}✓ OK${NC} (HTTP $response)"
            return 0
        else
            echo -e "${RED}✗ FAIL${NC} (HTTP $response, esperado $expected_status)"
            return 1
        fi
    else
        echo -e "${RED}✗ NO RESPONDE${NC}"
        return 1
    fi
}

# Función para verificar con JSON
check_json_service() {
    local service_name=$1
    local url=$2
    
    echo -n "Verificando $service_name... "
    
    if response=$(curl -s "$url" 2>/dev/null); then
        if echo "$response" | jq -e . >/dev/null 2>&1; then
            echo -e "${GREEN}✓ OK${NC}"
            echo "$response" | jq -C '.'
            return 0
        else
            echo -e "${RED}✗ FAIL${NC} (Respuesta no es JSON válido)"
            return 1
        fi
    else
        echo -e "${RED}✗ NO RESPONDE${NC}"
        return 1
    fi
}

# Contador de fallos
failures=0

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Health Checks"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Verificar servicios principales
check_json_service "Vote Service" "http://localhost:5000/healthz" || ((failures++))
echo ""
check_json_service "Worker Service" "http://localhost:3001/healthz" || ((failures++))
echo ""
check_json_service "Result Service" "http://localhost:5001/healthz" || ((failures++))
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Frontend Services"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

check_service "Vote Frontend" "http://localhost:5000" || ((failures++))
check_service "Result Frontend" "http://localhost:5001" || ((failures++))
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Metrics Endpoints"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

check_service "Vote Metrics" "http://localhost:5000/metrics" || ((failures++))
check_service "Worker Metrics" "http://localhost:3001/metrics" || ((failures++))
check_service "Result Metrics" "http://localhost:5001/metrics" || ((failures++))
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Vote Statistics"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

check_json_service "Vote Stats" "http://localhost:5000/stats" || ((failures++))
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Docker Containers"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

docker compose ps

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Resumen"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ $failures -eq 0 ]; then
    echo -e "${GREEN}✓ Todos los servicios funcionan correctamente!${NC}"
    echo ""
    echo "🌐 Accede a:"
    echo "   - Vote App:   http://localhost:5000"
    echo "   - Result App: http://localhost:5001"
    echo ""
    exit 0
else
    echo -e "${RED}✗ $failures verificación(es) fallaron${NC}"
    echo ""
    echo -e "${YELLOW}💡 Sugerencias:${NC}"
    echo "   1. Verifica que todos los contenedores estén corriendo: docker-compose ps"
    echo "   2. Revisa los logs: docker-compose logs -f"
    echo "   3. Reinicia los servicios: docker-compose restart"
    echo ""
    exit 1
fi
