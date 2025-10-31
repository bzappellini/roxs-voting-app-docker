#!/bin/bash

# Script para crear un nuevo repositorio en GitHub y hacer push

echo "🚀 Creando nuevo repositorio en GitHub..."
echo ""
echo "📋 Opciones:"
echo "1. Crear repositorio público"
echo "2. Crear repositorio privado"
echo ""
read -p "Selecciona una opción (1 o 2): " option

if [ "$option" = "1" ]; then
    visibility="public"
elif [ "$option" = "2" ]; then
    visibility="private"
else
    echo "❌ Opción inválida"
    exit 1
fi

read -p "📝 Nombre del repositorio (ej: roxs-voting-app-docker): " repo_name
read -p "📄 Descripción (opcional): " description

if [ -z "$repo_name" ]; then
    echo "❌ El nombre del repositorio es obligatorio"
    exit 1
fi

if [ -z "$description" ]; then
    description="ROXS DevOps Voting App - Complete Docker Infrastructure"
fi

echo ""
echo "📦 Creando repositorio: $repo_name"
echo "🔒 Visibilidad: $visibility"
echo "📄 Descripción: $description"
echo ""

# Crear repositorio usando GitHub CLI
if command -v gh &> /dev/null; then
    echo "✅ Usando GitHub CLI..."
    gh repo create "$repo_name" --$visibility --description "$description" --source=. --remote=origin-new
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ Repositorio creado exitosamente!"
        echo ""
        
        # Hacer push
        echo "📤 Subiendo código al repositorio..."
        git push origin-new master
        
        echo ""
        echo "🎉 ¡Todo listo!"
        echo "🔗 Tu repositorio: https://github.com/bzappellini/$repo_name"
        echo ""
        echo "📋 Comandos útiles:"
        echo "   git remote -v                    # Ver remotes"
        echo "   git push origin-new master       # Subir cambios"
        echo "   gh repo view --web               # Abrir en navegador"
    else
        echo "❌ Error al crear el repositorio"
        exit 1
    fi
else
    echo "⚠️  GitHub CLI (gh) no está instalado."
    echo ""
    echo "📋 Instrucciones manuales:"
    echo ""
    echo "1. Ve a https://github.com/new"
    echo "2. Crea un repositorio llamado: $repo_name"
    echo "3. Visibilidad: $visibility"
    echo "4. NO inicialices con README, .gitignore o licencia"
    echo "5. Ejecuta estos comandos:"
    echo ""
    echo "   git remote add origin-new https://github.com/bzappellini/$repo_name.git"
    echo "   git push -u origin-new master"
    echo ""
    echo "O instala GitHub CLI:"
    echo "   # En Ubuntu/Debian:"
    echo "   curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg"
    echo "   echo \"deb [arch=\$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main\" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null"
    echo "   sudo apt update"
    echo "   sudo apt install gh"
    echo "   gh auth login"
fi
