# Dotfiles

Configuración personal de dotfiles gestionada con GNU Stow.

## Prerequisitos

Instalar GNU Stow:

```bash
# Ubuntu/Debian
sudo apt-get install stow

# Fedora
sudo dnf install stow

# macOS
brew install stow

# Arch
sudo pacman -S stow
```

## Instalación

### Opción 1: Instalación completa

```bash
git clone https://github.com/TU_USUARIO/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
chmod +x install.sh
./install.sh
```

### Opción 2: Instalación selectiva

```bash
cd ~/.dotfiles
stow bash    # Solo configuración de bash
stow git     # Solo configuración de git
stow python  # Solo configuración de python
```

## Estructura

```
.dotfiles/
├── bash/            # Configuración de Bash
│   ├── .bashrc
│   ├── .bash_profile
│   ├── .aliases
│   ├── .aliases_local
│   ├── .fzf.bash
│   └── .up_function.sh
├── git/             # Configuración de Git
│   ├── .gitconfig
│   ├── .gitignore_global
│   └── .git-flow-completion.bash
├── python/          # Configuración de Python
│   └── .pythonrc.py
├── screen/          # Configuración de Screen
│   └── .screenrc
├── hg/              # Configuración de Mercurial
│   ├── .hgrc
│   └── .hgignore
├── jed/             # Configuración del editor JED
│   └── .jedrc
├── nano/            # Configuración del editor Nano
│   └── .nanorc
└── buildout-config/ # Configuración de Buildout
    ├── .buildout
    └── .zopeskel
```

## Comandos útiles

```bash
# Instalar un paquete
stow <paquete>

# Desinstalar un paquete
stow -D <paquete>

# Reinstalar un paquete (útil después de cambios)
stow -R <paquete>

# Ver qué haría stow sin hacer cambios
stow -n -v <paquete>

# Limpiar enlaces rotos
stow -D <paquete> && stow <paquete>
```

## Añadir nuevos dotfiles

1. Crea un nuevo directorio para el paquete
2. Mueve o crea el archivo con el nombre que tendría en `$HOME`
3. Ejecuta `stow <paquete>`

Ejemplo:
```bash
mkdir -p vim
mv ~/.vimrc vim/.vimrc
stow vim
```

## Resolución de conflictos

Si stow encuentra archivos existentes:

```bash
# Hacer backup del archivo existente
mv ~/.bashrc ~/.bashrc.backup

# Instalar con stow
stow bash
```
