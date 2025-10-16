# CloudBeaver Installer

Installation automatisée de CloudBeaver sur Debian 12/13 avec support PostgreSQL et Oracle.

## Description

CloudBeaver est une interface web open-source pour gérer des bases de données. Cette solution d'installation automatisée permet de déployer rapidement CloudBeaver avec les drivers JDBC pour PostgreSQL et Oracle.

### Fonctionnalités

- Installation automatique de Java OpenJDK 17
- Téléchargement et installation de CloudBeaver 24.3.4
- Configuration du service systemd
- Driver PostgreSQL pré-installé
- Support pour driver Oracle (installation manuelle)
- Génération automatique de mot de passe
- Déploiement manuel (script Bash) ou automatisé (Ansible)

## Prérequis

- Debian 12 ou 13
- Accès root ou sudo
- Minimum 2 Go de RAM (4 Go recommandés)
- Minimum 1 Go d'espace disque libre
- Connexion internet

## Installation rapide

### Méthode 1 : Installation directe (recommandée)

Installation en une seule commande via wget :

```bash
wget -qO- https://raw.githubusercontent.com/tiagomatiastm-prog/cloudbeaver-installer/master/install-cloudbeaver.sh | sudo bash
```

Ou avec curl :

```bash
curl -fsSL https://raw.githubusercontent.com/tiagomatiastm-prog/cloudbeaver-installer/master/install-cloudbeaver.sh | sudo bash
```

Pour télécharger le script et l'exécuter séparément :

```bash
# Avec wget
wget https://raw.githubusercontent.com/tiagomatiastm-prog/cloudbeaver-installer/master/install-cloudbeaver.sh
chmod +x install-cloudbeaver.sh
sudo ./install-cloudbeaver.sh

# Avec curl
curl -O https://raw.githubusercontent.com/tiagomatiastm-prog/cloudbeaver-installer/master/install-cloudbeaver.sh
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

Lors de la première connexion, vous devrez créer le compte administrateur. Le mot de passe suggéré est disponible dans `/root/cloudbeaver-info.txt`.

## Configuration des bases de données

### PostgreSQL

Le driver PostgreSQL est installé automatiquement. Vous pouvez ajouter des connexions directement depuis l'interface web.

### Oracle Database

Le driver Oracle nécessite une installation manuelle :

1. Télécharger `ojdbc11.jar` depuis [Oracle](https://www.oracle.com/database/technologies/appdev/jdbc-downloads.html)
2. Copier le fichier dans `/opt/cloudbeaver/drivers/oracle/`
3. Redémarrer le service : `systemctl restart cloudbeaver`

Voir [DEPLOYMENT.md](DEPLOYMENT.md#configuration-oracle) pour plus de détails.

## Structure du projet

```
cloudbeaver-installer/
├── install-cloudbeaver.sh    # Script d'installation principal
├── deploy-cloudbeaver.yml    # Playbook Ansible
├── inventory.ini             # Inventaire Ansible
├── DEPLOYMENT.md             # Guide de déploiement détaillé
└── README.md                 # Ce fichier
```

## Documentation

- [Guide de déploiement complet](DEPLOYMENT.md)
- [Documentation officielle CloudBeaver](https://cloudbeaver.io/docs/)
- [GitHub CloudBeaver](https://github.com/dbeaver/cloudbeaver)

## Commandes utiles

```bash
# Statut du service
systemctl status cloudbeaver

# Redémarrer le service
systemctl restart cloudbeaver

# Voir les logs
journalctl -u cloudbeaver -f

# Informations d'installation
cat /root/cloudbeaver-info.txt
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

- **CloudBeaver** : 24.3.4
- **Java** : OpenJDK 17
- **Driver PostgreSQL** : 42.7.4
- **Systèmes supportés** : Debian 12/13

---

**Date de création** : 2025-10-16
