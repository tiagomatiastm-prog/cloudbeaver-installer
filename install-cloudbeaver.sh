#!/bin/bash

#############################################
# Script d'installation de CloudBeaver via Docker
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
CLOUDBEAVER_VERSION="25.2.2"
CLOUDBEAVER_DIR="/opt/cloudbeaver"
LOG_FILE="/var/log/cloudbeaver-installation.log"
INFO_FILE="/root/cloudbeaver-info.txt"
CLOUDBEAVER_PORT="8978"

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

# Vérification de la distribution
if ! grep -qi "debian" /etc/os-release; then
    error "Ce script est conçu pour Debian. Distribution non supportée."
fi

log "=========================================="
log "Installation de CloudBeaver $CLOUDBEAVER_VERSION via Docker"
log "=========================================="

# Mise à jour du système
log "Mise à jour du système..."
apt-get update >> "$LOG_FILE" 2>&1

# Installation des prérequis
log "Installation des paquets requis..."
apt-get install -y ca-certificates curl gnupg lsb-release >> "$LOG_FILE" 2>&1

# Installation de Docker
log "Vérification de l'installation de Docker..."
if ! command -v docker &> /dev/null; then
    log "Installation de Docker..."

    # Ajout de la clé GPG officielle Docker
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc

    # Ajout du dépôt Docker
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt-get update >> "$LOG_FILE" 2>&1
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin >> "$LOG_FILE" 2>&1

    # Démarrage de Docker
    systemctl start docker
    systemctl enable docker

    log "Docker installé avec succès"
else
    log "Docker est déjà installé"
fi

# Vérification de Docker
docker --version >> "$LOG_FILE" 2>&1 || error "L'installation de Docker a échoué"
docker compose version >> "$LOG_FILE" 2>&1 || error "Docker Compose n'est pas disponible"

# Création du répertoire CloudBeaver
log "Création du répertoire d'installation..."
if [ -d "$CLOUDBEAVER_DIR" ]; then
    warning "Le répertoire $CLOUDBEAVER_DIR existe déjà, sauvegarde..."
    mv "$CLOUDBEAVER_DIR" "${CLOUDBEAVER_DIR}.backup.$(date +%Y%m%d%H%M%S)"
fi

mkdir -p "$CLOUDBEAVER_DIR"
mkdir -p "$CLOUDBEAVER_DIR/workspace"

# Génération du mot de passe admin
ADMIN_PASSWORD=$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-16)

# Création du fichier docker-compose.yml
log "Création du fichier docker-compose.yml..."
cat > "$CLOUDBEAVER_DIR/docker-compose.yml" << EOF
version: '3.8'

services:
  cloudbeaver:
    image: dbeaver/cloudbeaver:${CLOUDBEAVER_VERSION}
    container_name: cloudbeaver
    restart: unless-stopped
    ports:
      - "${CLOUDBEAVER_PORT}:8978"
    volumes:
      - ./workspace:/opt/cloudbeaver/workspace
    environment:
      - CB_SERVER_NAME=CloudBeaver
      - CB_SERVER_URL=http://localhost:${CLOUDBEAVER_PORT}
      - CB_ADMIN_NAME=admin
      - CB_ADMIN_PASSWORD=${ADMIN_PASSWORD}
    networks:
      - cloudbeaver-network

networks:
  cloudbeaver-network:
    driver: bridge
EOF

# Création du service systemd
log "Création du service systemd..."
cat > /etc/systemd/system/cloudbeaver.service << EOF
[Unit]
Description=CloudBeaver Docker Container
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$CLOUDBEAVER_DIR
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

# Démarrage de CloudBeaver
log "Démarrage de CloudBeaver..."
cd "$CLOUDBEAVER_DIR"
systemctl daemon-reload
systemctl enable cloudbeaver >> "$LOG_FILE" 2>&1
systemctl start cloudbeaver >> "$LOG_FILE" 2>&1

# Attente du démarrage
log "Attente du démarrage de CloudBeaver (30 secondes)..."
sleep 30

# Vérification du statut
if docker ps | grep -q cloudbeaver; then
    log "CloudBeaver est démarré avec succès"
else
    error "CloudBeaver n'a pas démarré correctement. Vérifiez les logs: docker logs cloudbeaver"
fi

# Récupération de l'adresse IP
IP_ADDRESS=$(hostname -I | awk '{print $1}')

# Sauvegarde des informations
log "Sauvegarde des informations de connexion..."
cat > "$INFO_FILE" << EOF
========================================
Informations d'installation CloudBeaver
========================================
Date d'installation: $(date)
Version CloudBeaver: $CLOUDBEAVER_VERSION
Méthode d'installation: Docker

Installation:
- Répertoire: $CLOUDBEAVER_DIR
- Port: $CLOUDBEAVER_PORT
- Container Docker: cloudbeaver

Accès Web:
- URL: http://$IP_ADDRESS:$CLOUDBEAVER_PORT
- Utilisateur admin: admin
- Mot de passe admin: $ADMIN_PASSWORD

Commandes utiles:
- Statut du service: systemctl status cloudbeaver
- Statut du container: docker ps | grep cloudbeaver
- Logs Docker: docker logs cloudbeaver
- Logs en temps réel: docker logs -f cloudbeaver
- Arrêt: systemctl stop cloudbeaver
- Démarrage: systemctl start cloudbeaver
- Redémarrage: systemctl restart cloudbeaver

Gestion Docker:
- Entrer dans le container: docker exec -it cloudbeaver /bin/bash
- Arrêter le container: docker stop cloudbeaver
- Démarrer le container: docker start cloudbeaver
- Recréer le container: cd $CLOUDBEAVER_DIR && docker compose up -d --force-recreate

Configuration:
- Fichier docker-compose: $CLOUDBEAVER_DIR/docker-compose.yml
- Données: $CLOUDBEAVER_DIR/workspace/

Prochaines étapes:
1. Accédez à l'interface web: http://$IP_ADDRESS:$CLOUDBEAVER_PORT
2. Connectez-vous avec les identifiants ci-dessus
3. Configurez vos connexions de bases de données

Support des bases de données:
- PostgreSQL (driver inclus)
- MySQL/MariaDB (driver inclus)
- Oracle (nécessite configuration supplémentaire)
- MongoDB (driver inclus)
- Et bien d'autres...

========================================
EOF

chmod 600 "$INFO_FILE"

# Affichage des informations
log "=========================================="
log "Installation terminée avec succès!"
log "=========================================="
echo ""
info "CloudBeaver est accessible à l'adresse: http://$IP_ADDRESS:$CLOUDBEAVER_PORT"
info "Utilisateur: admin"
info "Mot de passe: $ADMIN_PASSWORD"
info "Informations sauvegardées dans: $INFO_FILE"
info "Logs d'installation: $LOG_FILE"
echo ""
warning "IMPORTANT: Changez le mot de passe administrateur après la première connexion"
echo ""
log "=========================================="

exit 0
