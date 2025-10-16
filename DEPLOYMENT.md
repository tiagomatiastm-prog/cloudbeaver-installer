# Guide de déploiement CloudBeaver

## Table des matières

1. [Prérequis](#prérequis)
2. [Méthode 1 : Installation via script Bash](#méthode-1--installation-via-script-bash)
3. [Méthode 2 : Déploiement via Ansible](#méthode-2--déploiement-via-ansible)
4. [Post-installation](#post-installation)
5. [Configuration Oracle](#configuration-oracle)
6. [Dépannage](#dépannage)

---

## Prérequis

### Système requis
- **Système d'exploitation** : Debian 12 ou 13
- **RAM** : Minimum 2 Go (4 Go recommandés)
- **Espace disque** : Minimum 1 Go libre
- **Accès** : Droits root ou sudo
- **Réseau** : Accès internet pour le téléchargement des paquets

### Ports utilisés
- **8978** : Interface web CloudBeaver (par défaut)

---

## Méthode 1 : Installation via script Bash

### Installation locale

1. **Télécharger le script**
   ```bash
   git clone https://github.com/tiagomatiastm-prog/cloudbeaver-installer.git
   cd cloudbeaver-installer
   ```

2. **Rendre le script exécutable**
   ```bash
   chmod +x install-cloudbeaver.sh
   ```

3. **Exécuter le script en tant que root**
   ```bash
   sudo ./install-cloudbeaver.sh
   ```

4. **Suivre les instructions affichées**
   Le script va :
   - Installer Java OpenJDK 17
   - Télécharger et installer CloudBeaver 24.3.4
   - Installer le driver PostgreSQL
   - Créer et démarrer le service systemd
   - Générer un mot de passe suggéré

5. **Accéder à l'interface**
   ```
   http://VOTRE_IP:8978
   ```

### Installation sur serveur distant

```bash
# Copier le script sur le serveur
scp install-cloudbeaver.sh user@serveur:/tmp/

# Se connecter et exécuter
ssh user@serveur
sudo /tmp/install-cloudbeaver.sh
```

---

## Méthode 2 : Déploiement via Ansible

### Prérequis Ansible
- Ansible 2.9+ installé sur la machine de contrôle
- Accès SSH configuré vers le(s) serveur(s) cible(s)
- Clés SSH configurées (recommandé)

### Configuration

1. **Cloner le dépôt**
   ```bash
   git clone https://github.com/tiagomatiastm-prog/cloudbeaver-installer.git
   cd cloudbeaver-installer
   ```

2. **Modifier l'inventaire**
   Éditer `inventory.ini` :
   ```ini
   [cloudbeaver_servers]
   cloudbeaver-prod ansible_host=192.168.1.10 ansible_user=debian ansible_become=yes
   ```

3. **Tester la connectivité**
   ```bash
   ansible -i inventory.ini cloudbeaver_servers -m ping
   ```

### Déploiement

1. **Déploiement sur tous les serveurs**
   ```bash
   ansible-playbook -i inventory.ini deploy-cloudbeaver.yml
   ```

2. **Déploiement sur un serveur spécifique**
   ```bash
   ansible-playbook -i inventory.ini deploy-cloudbeaver.yml --limit cloudbeaver-prod
   ```

3. **Déploiement avec mode verbeux (debug)**
   ```bash
   ansible-playbook -i inventory.ini deploy-cloudbeaver.yml -vvv
   ```

### Variables personnalisables

Vous pouvez surcharger les variables dans le playbook :

```bash
ansible-playbook -i inventory.ini deploy-cloudbeaver.yml \
  -e "cloudbeaver_version=24.3.4" \
  -e "cloudbeaver_port=8978"
```

---

## Post-installation

### Première connexion

1. **Accéder à l'interface web**
   ```
   http://VOTRE_IP:8978
   ```

2. **Créer le compte administrateur**
   - Lors de la première connexion, CloudBeaver vous invite à créer le compte admin
   - Utilisez le mot de passe suggéré dans `/root/cloudbeaver-info.txt` ou créez le vôtre
   - **Important** : Notez bien vos identifiants

3. **Configuration initiale**
   - Configurer les paramètres de l'application
   - Ajouter vos connexions de bases de données

### Connexions aux bases de données

#### PostgreSQL
Le driver est déjà installé. Pour ajouter une connexion :
1. Cliquer sur "New Connection"
2. Sélectionner "PostgreSQL"
3. Renseigner :
   - Host : IP du serveur PostgreSQL
   - Port : 5432 (par défaut)
   - Database : nom de la base
   - Username : utilisateur
   - Password : mot de passe

#### Oracle (nécessite installation manuelle)
Voir section [Configuration Oracle](#configuration-oracle)

---

## Configuration Oracle

### Téléchargement du driver JDBC

Le driver Oracle (ojdbc) ne peut pas être téléchargé automatiquement pour des raisons de licence.

1. **Télécharger le driver**
   - Aller sur : https://www.oracle.com/database/technologies/appdev/jdbc-downloads.html
   - Télécharger `ojdbc11.jar` (pour Oracle 21c+) ou `ojdbc8.jar` (pour Oracle 18c/19c)

2. **Installer le driver**
   ```bash
   # Copier le driver sur le serveur
   scp ojdbc11.jar root@serveur:/opt/cloudbeaver/drivers/oracle/

   # Vérifier les permissions
   ssh root@serveur
   chown cloudbeaver:cloudbeaver /opt/cloudbeaver/drivers/oracle/ojdbc11.jar
   chmod 644 /opt/cloudbeaver/drivers/oracle/ojdbc11.jar
   ```

3. **Redémarrer CloudBeaver**
   ```bash
   systemctl restart cloudbeaver
   ```

4. **Ajouter une connexion Oracle**
   - New Connection → Oracle
   - Renseigner les informations de connexion
   - Format de connexion :
     ```
     Host: oracle-server.example.com
     Port: 1521
     Service Name: ORCL (ou SID)
     Username: system
     Password: ********
     ```

---

## Dépannage

### Vérifier le statut du service

```bash
systemctl status cloudbeaver
```

### Consulter les logs

```bash
# Logs en temps réel
journalctl -u cloudbeaver -f

# Logs complets
journalctl -u cloudbeaver -n 100

# Log d'installation
cat /var/log/cloudbeaver-installation.log
```

### Redémarrer le service

```bash
systemctl restart cloudbeaver
```

### CloudBeaver ne démarre pas

1. **Vérifier Java**
   ```bash
   java -version
   ```

2. **Vérifier les permissions**
   ```bash
   ls -la /opt/cloudbeaver/
   # Le propriétaire doit être cloudbeaver:cloudbeaver
   ```

3. **Vérifier le port**
   ```bash
   netstat -tlnp | grep 8978
   # ou
   ss -tlnp | grep 8978
   ```

4. **Tester manuellement**
   ```bash
   su - cloudbeaver -s /bin/bash
   cd /opt/cloudbeaver
   ./run-server.sh
   ```

### Réinitialiser CloudBeaver

Si vous devez réinitialiser complètement :

```bash
# Arrêter le service
systemctl stop cloudbeaver

# Supprimer les données (garde la configuration)
rm -rf /opt/cloudbeaver/workspace/.metadata

# Ou réinstaller complètement
rm -rf /opt/cloudbeaver
./install-cloudbeaver.sh
```

### Port déjà utilisé

Modifier le port dans la configuration :

```bash
# Éditer le fichier de configuration
nano /opt/cloudbeaver/conf/cloudbeaver.conf

# Chercher et modifier :
# server.port=8978
# Par exemple : server.port=9000

# Redémarrer
systemctl restart cloudbeaver
```

### Pare-feu

Si CloudBeaver n'est pas accessible depuis l'extérieur :

```bash
# UFW
ufw allow 8978/tcp
ufw reload

# iptables
iptables -A INPUT -p tcp --dport 8978 -j ACCEPT
iptables-save > /etc/iptables/rules.v4
```

---

## Commandes utiles

```bash
# Statut du service
systemctl status cloudbeaver

# Démarrer
systemctl start cloudbeaver

# Arrêter
systemctl stop cloudbeaver

# Redémarrer
systemctl restart cloudbeaver

# Logs en temps réel
journalctl -u cloudbeaver -f

# Informations d'installation
cat /root/cloudbeaver-info.txt

# Version de CloudBeaver
cat /opt/cloudbeaver/version.txt
```

---

## Ressources

- **Documentation officielle** : https://cloudbeaver.io/docs/
- **GitHub CloudBeaver** : https://github.com/dbeaver/cloudbeaver
- **Support** : https://github.com/dbeaver/cloudbeaver/issues

---

**Auteur** : Tiago
**Date** : 2025-10-16
**Version** : 1.0
