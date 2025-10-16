# CloudBeaver Installer

Installation automatisée de CloudBeaver via Docker sur Debian 12/13 avec support PostgreSQL, MySQL, Oracle et MongoDB.

## Description

CloudBeaver est une interface web open-source pour gérer des bases de données. Cette solution d'installation automatisée permet de déployer rapidement CloudBeaver 25.2.2 via Docker avec tous les drivers JDBC nécessaires.

### Fonctionnalités

- Installation automatique de Docker et Docker Compose
- Déploiement de CloudBeaver 25.2.2 via container Docker
- Configuration du service systemd
- Support multi-bases de données (PostgreSQL, MySQL, Oracle, MongoDB, etc.)
- Génération automatique de mot de passe admin
- Déploiement manuel (script Bash) ou automatisé (Ansible)
- Persistence des données via volumes Docker

## Prérequis

- Debian 12 ou 13
- Accès root ou sudo
- Minimum 2 Go de RAM (4 Go recommandés)
- Minimum 2 Go d'espace disque libre
- Connexion internet

## Installation rapide

### Méthode 1 : Installation directe (recommandée)

Installation en une seule commande via curl :

```bash
curl -fsSL https://raw.githubusercontent.com/tiagomatiastm-prog/cloudbeaver-installer/master/install-cloudbeaver.sh | sudo bash
```

Ou avec wget :

```bash
wget -qO- https://raw.githubusercontent.com/tiagomatiastm-prog/cloudbeaver-installer/master/install-cloudbeaver.sh | sudo bash
```

Pour télécharger le script et l'exécuter séparément :

```bash
# Avec curl
curl -O https://raw.githubusercontent.com/tiagomatiastm-prog/cloudbeaver-installer/master/install-cloudbeaver.sh
chmod +x install-cloudbeaver.sh
sudo ./install-cloudbeaver.sh

# Avec wget
wget https://raw.githubusercontent.com/tiagomatiastm-prog/cloudbeaver-installer/master/install-cloudbeaver.sh
chmod +x install-cloudbeaver.sh
sudo ./install-cloudbeaver.sh
```

### Méthode 2 : Ansible (déploiement distant)

```bash
git clone https://github.com/tiagomatiastm-prog/cloudbeaver-installer.git
cd cloudbeaver-installer
# Modifier inventory.ini avec vos serveurs
ansible-playbook -i inventory.ini deploy-cloudbeaver.yml
```

## Accès à l'interface

Après l'installation, CloudBeaver est accessible via :

```
http://VOTRE_IP:8978
```

Les identifiants de connexion sont générés automatiquement et sauvegardés dans `/root/cloudbeaver-info.txt`.

## Configuration des bases de données

### PostgreSQL, MySQL, MongoDB

Les drivers sont déjà inclus dans l'image Docker. Vous pouvez ajouter des connexions directement depuis l'interface web.

### Oracle Database

Pour Oracle, une configuration supplémentaire peut être nécessaire. Consultez la [documentation officielle](https://cloudbeaver.io/docs/).

## Structure du projet

```
cloudbeaver-installer/
├── install-cloudbeaver.sh       # Script d'installation principal
├── deploy-cloudbeaver.yml       # Playbook Ansible
├── inventory.ini                # Inventaire Ansible
├── docker-compose.example.yml   # Exemple de configuration Docker Compose
├── DEPLOYMENT.md                # Guide de déploiement détaillé
└── README.md                    # Ce fichier
```

## Documentation

- [Guide de déploiement complet](DEPLOYMENT.md)
- [Documentation officielle CloudBeaver](https://cloudbeaver.io/docs/)
- [GitHub CloudBeaver](https://github.com/dbeaver/cloudbeaver)

## Commandes utiles

```bash
# Statut du service
systemctl status cloudbeaver

# Statut du container Docker
docker ps | grep cloudbeaver

# Logs en temps réel
docker logs -f cloudbeaver

# Redémarrer le service
systemctl restart cloudbeaver

# Informations d'installation
cat /root/cloudbeaver-info.txt
```

## Gestion Docker

```bash
# Entrer dans le container
docker exec -it cloudbeaver /bin/bash

# Arrêter le container
docker stop cloudbeaver

# Démarrer le container
docker start cloudbeaver

# Recréer le container
cd /opt/cloudbeaver && docker compose up -d --force-recreate
```

## Ports utilisés

- **8978** : Interface web CloudBeaver (par défaut)

## Dépannage

Consultez la section [Dépannage](DEPLOYMENT.md#dépannage) dans DEPLOYMENT.md pour résoudre les problèmes courants.

## Support

Pour signaler un bug ou demander une fonctionnalité :
- Créer une issue sur GitHub : [Issues](https://github.com/tiagomatiastm-prog/cloudbeaver-installer/issues)

## Licence

Ce projet est fourni "tel quel" sans garantie. Utilisation à vos propres risques.

## Auteur

**Tiago**

## Versions

- **CloudBeaver** : 25.2.2
- **Docker** : Latest (installé automatiquement)
- **Docker Compose** : Plugin v2 (installé automatiquement)
- **Systèmes supportés** : Debian 12/13

---

**Date de création** : 2025-10-16
