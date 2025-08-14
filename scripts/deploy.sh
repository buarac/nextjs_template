#!/bin/bash

# Script de déploiement pour NUC avec PM2
# Usage: ./scripts/deploy.sh v1.1.0

set -e  # Exit on error

VERSION=${1:-"latest"}
REPO="buarac/nextjs_template"
APP_DIR="/home/buarac/app/nextjs_template/scripts/myapp"
APP_NAME="nextjs-template"

echo "🚀 Déploiement de la version: $VERSION"

# 1. Créer le répertoire d'application
mkdir -p "$APP_DIR"
cd "$APP_DIR"

# 2. Télécharger l'artifact
echo "📦 Téléchargement de build.tar.gz..."
wget -O build.tar.gz "https://github.com/$REPO/releases/download/$VERSION/build.tar.gz"

# 3. Nettoyer et extraire
echo "🧹 Nettoyage et extraction..."
rm -rf .next node_modules package.json package-lock.json prisma/
tar -xzf build.tar.gz
rm build.tar.gz

# 4. Installer les dépendances de production
echo "📦 Installation des dépendances..."
npm ci --production

# 5. Vérifier les variables d'environnement
echo "🔧 Vérification de .env.production..."
if [ ! -f ".env.production" ]; then
    echo "⚠️  ATTENTION: Créez le fichier .env.production avec:"
    echo "DATABASE_URL=postgresql://user:pass@localhost/db"
    echo "NEXTAUTH_SECRET=your-production-secret"
    exit 1
fi

# 6. Migrations Prisma
echo "🗃️ Migrations de base de données..."
cp .env.production .env
npx prisma migrate deploy
rm .env

# 7. Gérer l'application avec PM2
echo "🔄 Gestion PM2..."

# Vérifier si PM2 est installé
if ! command -v pm2 &> /dev/null; then
    echo "⚠️  PM2 n'est pas installé. Installation..."
    npm install -g pm2
fi

# Arrêter l'application existante (sans erreur si elle n'existe pas)
pm2 delete "$APP_NAME" 2>/dev/null || echo "ℹ️  Application $APP_NAME n'était pas en cours d'exécution"

# Créer le dossier logs
mkdir -p ./logs

# Démarrer l'application avec PM2 (config file ou commande simple)
echo "🌟 Démarrage avec PM2..."
if [ -f "ecosystem.config.js" ]; then
    echo "ℹ️  Utilisation du fichier de configuration ecosystem.config.js"
    pm2 start ecosystem.config.js
else
    echo "ℹ️  Démarrage avec configuration par défaut"
    pm2 start npm --name "$APP_NAME" -- run start
fi

# Sauvegarder la configuration PM2
pm2 save

# Configurer PM2 pour démarrer automatiquement au boot (une seule fois)
if ! pm2 startup | grep -q "already"; then
    echo "🔧 Configuration du démarrage automatique PM2..."
    pm2 startup systemd -u $(whoami) --hp $(eval echo ~$(whoami))
fi

# Afficher le statut
echo ""
echo "✅ Déploiement terminé !"
echo "📊 Version déployée: $VERSION"
echo ""
echo "🔍 Statut PM2:"
pm2 list
echo ""
echo "📋 Commandes utiles:"
echo "  pm2 list                    # Liste des apps"
echo "  pm2 logs $APP_NAME          # Voir les logs"
echo "  pm2 restart $APP_NAME       # Redémarrer"
echo "  pm2 stop $APP_NAME          # Arrêter"
echo "  pm2 monit                   # Interface de monitoring"
echo ""
echo "🌐 API Health: curl http://localhost:3000/api/health"