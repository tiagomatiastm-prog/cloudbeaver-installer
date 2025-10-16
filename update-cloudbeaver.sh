#!/bin/bash

#############################################
# Script de mise à jour de CloudBeaver
# Pour Debian 12/13
# Auteur: Tiago
# Date: 2025-10-16
#############################################

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
CLOUDBEAVER_DIR="/opt/cloudbeaver"
DOCKER_COMPOSE_FILE="$CLOUDBEAVER_DIR/docker-compose.yml"
BACKUP_DIR="$CLOUDBEAVER_DIR/workspace.backup"
LOG_FILE="/var/log/cloudbeaver-update.log"

# Fonction d'affichage
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERREUR:${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] ATTENTION:${NC} $1" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] INFO:${NC} $1" | tee -a "$LOG_FILE"
}

# Vérification des privilèges root
if [[ $EUID -ne 0 ]]; then
   error "Ce script doit être exécuté en tant que root"
fi

# Vérification que CloudBeaver est installé
if [ ! -d "$CLOUDBEAVER_DIR" ]; then
    error "CloudBeaver n'est pas installé dans $CLOUDBEAVER_DIR"
fi

if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
    error "Fichier docker-compose.yml introuvable"
fi

log "=========================================="
log "Mise à jour de CloudBeaver"
log "=========================================="

# Récupération de la version actuelle
CURRENT_VERSION=$(grep "image: dbeaver/cloudbeaver:" "$DOCKER_COMPOSE_FILE" | sed 's/.*cloudbeaver://' | tr -d ' ')
log "Version actuelle : $CURRENT_VERSION"

# Demande de la nouvelle version
echo ""
info "Versions disponibles :"
info "  - Numéro de version spécifique (ex: 25.3.0)"
info "  - 'latest' pour la dernière version stable"
echo ""
read -p "Version cible (ou 'latest') : " TARGET_VERSION

if [ -z "$TARGET_VERSION" ]; then
    error "Version non spécifiée"
fi

log "Version cible : $TARGET_VERSION"

# Confirmation
echo ""
warning "Cette opération va :"
warning "  1. Faire une sauvegarde du workspace"
warning "  2. Arrêter CloudBeaver"
warning "  3. Mettre à jour vers la version $TARGET_VERSION"
warning "  4. Redémarrer CloudBeaver"
echo ""
read -p "Continuer ? (o/N) : " CONFIRM

if [[ ! "$CONFIRM" =~ ^[oO]$ ]]; then
    log "Mise à jour annulée par l'utilisateur"
    exit 0
fi

# Sauvegarde du workspace
log "Sauvegarde du workspace..."
if [ -d "$BACKUP_DIR" ]; then
    rm -rf "$BACKUP_DIR"
fi
cp -r "$CLOUDBEAVER_DIR/workspace" "$BACKUP_DIR"
log "Sauvegarde créée : $BACKUP_DIR"

# Arrêt du service
log "Arrêt du service CloudBeaver..."
systemctl stop cloudbeaver

# Vérification que le container est arrêté
sleep 2
if docker ps | grep -q cloudbeaver; then
    warning "Le container est encore en cours d'exécution, arrêt forcé..."
    docker stop cloudbeaver || true
fi

# Mise à jour du docker-compose.yml
log "Mise à jour de la version dans docker-compose.yml..."
sed -i "s|image: dbeaver/cloudbeaver:.*|image: dbeaver/cloudbeaver:${TARGET_VERSION}|" "$DOCKER_COMPOSE_FILE"

# Vérification de la modification
NEW_VERSION=$(grep "image: dbeaver/cloudbeaver:" "$DOCKER_COMPOSE_FILE" | sed 's/.*cloudbeaver://' | tr -d ' ')
if [ "$NEW_VERSION" != "$TARGET_VERSION" ]; then
    error "Échec de la mise à jour du fichier docker-compose.yml"
fi

log "Fichier docker-compose.yml mis à jour"

# Téléchargement de la nouvelle image
log "Téléchargement de la nouvelle image Docker..."
cd "$CLOUDBEAVER_DIR"
docker compose pull

# Suppression de l'ancien container
log "Suppression de l'ancien container..."
docker compose down || true

# Démarrage avec la nouvelle version
log "Démarrage de CloudBeaver avec la version $TARGET_VERSION..."
systemctl start cloudbeaver

# Attente du démarrage
log "Attente du démarrage (30 secondes)..."
sleep 30

# Vérification
if docker ps | grep -q cloudbeaver; then
    log "✓ Container CloudBeaver démarré avec succès"

    # Vérification HTTP
    if curl -s http://localhost:8978 > /dev/null; then
        log "✓ Interface web accessible"
    else
        warning "L'interface web ne répond pas encore, attendez quelques instants"
    fi

    # Affichage de la version
    RUNNING_VERSION=$(docker inspect cloudbeaver --format='{{.Config.Image}}' | sed 's/.*://')
    log "Version en cours d'exécution : $RUNNING_VERSION"

else
    error "Le container CloudBeaver n'a pas démarré. Consultez les logs : docker logs cloudbeaver"
fi

# Récupération de l'IP
IP_ADDRESS=$(hostname -I | awk '{print $1}')

# Résumé
log "=========================================="
log "Mise à jour terminée avec succès!"
log "=========================================="
echo ""
info "Version précédente : $CURRENT_VERSION"
info "Nouvelle version : $TARGET_VERSION"
info "URL d'accès : http://$IP_ADDRESS:8978"
info "Sauvegarde du workspace : $BACKUP_DIR"
echo ""
info "Commandes utiles :"
info "  - Logs : docker logs -f cloudbeaver"
info "  - Statut : systemctl status cloudbeaver"
info "  - Restaurer la sauvegarde : cp -r $BACKUP_DIR $CLOUDBEAVER_DIR/workspace"
echo ""
log "=========================================="

# Nettoyage des anciennes images
read -p "Supprimer l'ancienne image Docker pour libérer de l'espace ? (o/N) : " CLEANUP
if [[ "$CLEANUP" =~ ^[oO]$ ]]; then
    log "Nettoyage des anciennes images..."
    docker image prune -f
    log "Nettoyage terminé"
fi

exit 0
