#!/bin/bash

#############################################
# Script d'installation de CloudBeaver
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
CLOUDBEAVER_VERSION="24.3.4"
CLOUDBEAVER_DIR="/opt/cloudbeaver"
CLOUDBEAVER_USER="cloudbeaver"
LOG_FILE="/var/log/cloudbeaver-installation.log"
INFO_FILE="/root/cloudbeaver-info.txt"

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
log "Installation de CloudBeaver $CLOUDBEAVER_VERSION"
log "=========================================="

# Mise à jour du système
log "Mise à jour du système..."
apt-get update >> "$LOG_FILE" 2>&1

# Installation de Java (OpenJDK 17)
log "Installation de Java OpenJDK 17..."
apt-get install -y openjdk-17-jre-headless wget unzip curl >> "$LOG_FILE" 2>&1

# Vérification de Java
java -version >> "$LOG_FILE" 2>&1 || error "L'installation de Java a échoué"
log "Java installé avec succès"

# Création de l'utilisateur CloudBeaver
log "Création de l'utilisateur système $CLOUDBEAVER_USER..."
if ! id "$CLOUDBEAVER_USER" &>/dev/null; then
    useradd -r -s /bin/false -d "$CLOUDBEAVER_DIR" "$CLOUDBEAVER_USER"
    log "Utilisateur $CLOUDBEAVER_USER créé"
else
    warning "L'utilisateur $CLOUDBEAVER_USER existe déjà"
fi

# Téléchargement de CloudBeaver
log "Téléchargement de CloudBeaver $CLOUDBEAVER_VERSION..."
cd /tmp
DOWNLOAD_URL="https://github.com/dbeaver/cloudbeaver/releases/download/${CLOUDBEAVER_VERSION}/cloudbeaver-${CLOUDBEAVER_VERSION}.zip"

wget -q --show-progress "$DOWNLOAD_URL" -O cloudbeaver.zip || error "Échec du téléchargement de CloudBeaver"

# Extraction de CloudBeaver
log "Extraction de CloudBeaver..."
unzip -q cloudbeaver.zip -d /tmp/ || error "Échec de l'extraction"

# Installation dans /opt
log "Installation de CloudBeaver dans $CLOUDBEAVER_DIR..."
if [ -d "$CLOUDBEAVER_DIR" ]; then
    warning "Le répertoire $CLOUDBEAVER_DIR existe déjà, sauvegarde..."
    mv "$CLOUDBEAVER_DIR" "${CLOUDBEAVER_DIR}.backup.$(date +%Y%m%d%H%M%S)"
fi

mv /tmp/cloudbeaver "$CLOUDBEAVER_DIR"
chown -R "$CLOUDBEAVER_USER:$CLOUDBEAVER_USER" "$CLOUDBEAVER_DIR"
chmod +x "$CLOUDBEAVER_DIR/run-server.sh"

# Installation des drivers JDBC
log "Installation des drivers JDBC pour PostgreSQL et Oracle..."

# Driver PostgreSQL
POSTGRES_DRIVER_VERSION="42.7.4"
POSTGRES_DRIVER_URL="https://jdbc.postgresql.org/download/postgresql-${POSTGRES_DRIVER_VERSION}.jar"
wget -q "$POSTGRES_DRIVER_URL" -O "$CLOUDBEAVER_DIR/drivers/postgresql/postgresql-${POSTGRES_DRIVER_VERSION}.jar" || warning "Échec du téléchargement du driver PostgreSQL"

# Driver Oracle (ojdbc11 pour Oracle 21c)
info "Pour Oracle, le driver doit être téléchargé manuellement depuis Oracle (licence)"
info "Téléchargez ojdbc11.jar depuis: https://www.oracle.com/database/technologies/appdev/jdbc-downloads.html"
info "Et placez-le dans: $CLOUDBEAVER_DIR/drivers/oracle/"
mkdir -p "$CLOUDBEAVER_DIR/drivers/oracle"
chown -R "$CLOUDBEAVER_USER:$CLOUDBEAVER_USER" "$CLOUDBEAVER_DIR/drivers"

# Configuration de CloudBeaver
log "Configuration de CloudBeaver..."

# Génération du mot de passe admin
ADMIN_PASSWORD=$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-16)

# Configuration du fichier server.xml si nécessaire
# CloudBeaver se configure via l'interface web au premier démarrage

# Création du service systemd
log "Création du service systemd..."
cat > /etc/systemd/system/cloudbeaver.service << EOF
[Unit]
Description=CloudBeaver Server
After=network.target

[Service]
Type=simple
User=$CLOUDBEAVER_USER
Group=$CLOUDBEAVER_USER
WorkingDirectory=$CLOUDBEAVER_DIR
ExecStart=$CLOUDBEAVER_DIR/run-server.sh
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Activation et démarrage du service
log "Activation et démarrage du service CloudBeaver..."
systemctl daemon-reload
systemctl enable cloudbeaver >> "$LOG_FILE" 2>&1
systemctl start cloudbeaver >> "$LOG_FILE" 2>&1

# Attente du démarrage
log "Attente du démarrage de CloudBeaver..."
sleep 10

# Vérification du statut
if systemctl is-active --quiet cloudbeaver; then
    log "CloudBeaver est démarré avec succès"
else
    error "CloudBeaver n'a pas démarré correctement. Vérifiez les logs: journalctl -u cloudbeaver"
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

Installation:
- Répertoire: $CLOUDBEAVER_DIR
- Utilisateur système: $CLOUDBEAVER_USER
- Port par défaut: 8978

Accès Web:
- URL: http://$IP_ADDRESS:8978
- Premier utilisateur admin à créer lors de la première connexion
- Mot de passe suggéré: $ADMIN_PASSWORD

Drivers JDBC installés:
- PostgreSQL: Version $POSTGRES_DRIVER_VERSION
- Oracle: À installer manuellement (voir documentation)

Commandes utiles:
- Statut: systemctl status cloudbeaver
- Arrêt: systemctl stop cloudbeaver
- Démarrage: systemctl start cloudbeaver
- Redémarrage: systemctl restart cloudbeaver
- Logs: journalctl -u cloudbeaver -f

Configuration:
- Fichier de configuration: $CLOUDBEAVER_DIR/conf/
- Données: $CLOUDBEAVER_DIR/workspace/

Prochaines étapes:
1. Accédez à l'interface web: http://$IP_ADDRESS:8978
2. Créez le premier compte administrateur
3. Pour Oracle, téléchargez le driver JDBC depuis:
   https://www.oracle.com/database/technologies/appdev/jdbc-downloads.html
   Et placez-le dans: $CLOUDBEAVER_DIR/drivers/oracle/

========================================
EOF

chmod 600 "$INFO_FILE"

# Affichage des informations
log "=========================================="
log "Installation terminée avec succès!"
log "=========================================="
echo ""
info "CloudBeaver est accessible à l'adresse: http://$IP_ADDRESS:8978"
info "Informations sauvegardées dans: $INFO_FILE"
info "Logs d'installation: $LOG_FILE"
echo ""
warning "IMPORTANT: Lors de la première connexion, vous devrez créer le compte administrateur"
warning "Mot de passe suggéré: $ADMIN_PASSWORD"
echo ""
info "Pour Oracle DB, installez manuellement le driver ojdbc11.jar:"
info "  1. Téléchargez depuis: https://www.oracle.com/database/technologies/appdev/jdbc-downloads.html"
info "  2. Placez dans: $CLOUDBEAVER_DIR/drivers/oracle/"
info "  3. Redémarrez: systemctl restart cloudbeaver"
echo ""
log "=========================================="

# Nettoyage
rm -f /tmp/cloudbeaver.zip

exit 0
