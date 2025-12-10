#!/bin/bash

set -e

DOTFILES_DIR="$HOME/.dotfiles"
cd "$DOTFILES_DIR"

echo "🔧 Instalando dotfiles con GNU Stow..."

if ! command -v stow &> /dev/null; then
    echo "❌ GNU Stow no está instalado. Instálalo con:"
    echo "  Ubuntu/Debian: sudo apt-get install stow"
    echo "  Fedora: sudo dnf install stow"
    echo "  macOS: brew install stow"
    exit 1
fi

PACKAGES=(
    "bash"
    "git"
    "screen"
    "hg"
    "jed"
    "nano"
    "buildout-config"
)

# Packages to be stowed in ~/.config
CONFIG_PACKAGES=(
    "activitywatch"
    "tmux"
    "kitty"
    "zed"
)

for package in "${PACKAGES[@]}"; do
    if [ -d "$package" ]; then
        echo "📦 Instalando $package en $HOME..."
        stow -v -t "$HOME" "$package"
    else
        echo "⚠️  Paquete $package no encontrado, saltando..."
    fi
done

for package in "${CONFIG_PACKAGES[@]}"; do
    if [ -d "$package" ]; then
        echo "📦 Instalando $package en ~/.config/$package..."
        mkdir -p "$HOME/.config/$package"
        stow -v -t "$HOME/.config/$package" "$package"
    else
        echo "⚠️  Paquete $package no encontrado, saltando..."
    fi
done

echo ""
echo "✅ ¡Dotfiles instalados exitosamente!"
echo ""
echo "Comandos útiles:"
echo "  stow <paquete>      # Instalar un paquete específico"
echo "  stow -D <paquete>   # Desinstalar un paquete"
echo "  stow -R <paquete>   # Reinstalar un paquete"
echo ""
ALL_PACKAGES=("${PACKAGES[@]}" "${CONFIG_PACKAGES[@]}")
echo "Paquetes disponibles: ${ALL_PACKAGES[*]}"
