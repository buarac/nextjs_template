#!/bin/bash

# Script de création de base de données pour les projets Next.js
# Usage: ./scripts/create-database.sh [PROJECT_NAME] [ENV] [NUC_HOST]
#
# PROJECT_NAME: nom du projet (ex: mon-app)
# ENV: dev|staging|stable (défaut: dev)
# NUC_HOST: adresse IP du NUC (défaut depuis variable d'environnement)

set -e  # Exit on error

# Configuration
PROJECT_NAME=${1:-$(basename $(pwd))}
ENV=${2:-"dev"}

# Charger la configuration NUC si disponible
if [ -f ".env.nuc" ]; then
    echo "📋 Chargement de la configuration .env.nuc..."
    source .env.nuc
    # Exporter PGPASSWORD si défini pour l'authentification PostgreSQL
    if [ -n "$PGPASSWORD" ]; then
        export PGPASSWORD
    fi
else
    echo "⚠️  Fichier .env.nuc non trouvé. Créez-le avec:"
    echo "   cp .env.nuc.example .env.nuc"
    echo "   puis configurez NUC_HOST avec l'IP de votre serveur"
    exit 1
fi

NUC_HOST=${3:-${NUC_HOST:-"localhost"}}
NUC_USER=${NUC_USER:-"postgres"}
NUC_PORT=${NUC_PORT:-"5432"}

# Validation de l'environnement
if [[ ! "$ENV" =~ ^(dev|staging|stable)$ ]]; then
    echo "❌ Environnement invalide: $ENV"
    echo "Environnements supportés: dev, staging, stable"
    exit 1
fi

# Construction du nom de la base de données
DB_NAME="${PROJECT_NAME}-${ENV}"
DB_USER="user_${PROJECT_NAME//-/_}_${ENV}"
DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)

echo "🗃️  Configuration de la base de données"
echo "📍 Serveur: $NUC_HOST:$NUC_PORT"
echo "🗂️  Base: $DB_NAME"
echo "👤 Utilisateur: $DB_USER"
echo "🔑 Mot de passe: [généré automatiquement]"
echo ""

# Ajouter libpq au PATH si disponible
if [ -d "/opt/homebrew/opt/libpq/bin" ]; then
    export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
elif [ -d "/usr/local/opt/libpq/bin" ]; then
    export PATH="/usr/local/opt/libpq/bin:$PATH"
fi

# Vérifier que psql est disponible
if ! command -v psql &> /dev/null; then
    echo "❌ Le client PostgreSQL (psql) n'est pas installé sur cette machine"
    echo ""
    echo "🛠️  Solutions possibles :"
    echo "1. Installer uniquement le client PostgreSQL (recommandé) :"
    echo "   brew install libpq"
    echo "   echo 'export PATH=\"/opt/homebrew/opt/libpq/bin:\$PATH\"' >> ~/.zshrc"
    echo "   source ~/.zshrc"
    echo ""
    echo "2. Utiliser Docker temporairement :"
    echo "   docker run --rm -it postgres:15 psql \"postgresql://$NUC_USER@$NUC_HOST:$NUC_PORT/postgres\" -c \"SELECT 1;\""
    echo ""
    echo "3. Installer PostgreSQL complet (non recommandé) :"
    echo "   brew install postgresql"
    echo ""
    echo "Relancez ce script après installation du client PostgreSQL."
    exit 1
fi

# Test de connexion
echo "🔍 Test de connexion au serveur PostgreSQL..."
if ! psql "postgresql://$NUC_USER@$NUC_HOST:$NUC_PORT/postgres" -c "SELECT 1;" >/dev/null 2>&1; then
    echo "❌ Impossible de se connecter au serveur PostgreSQL"
    echo "Vérifiez:"
    echo "  - Le serveur PostgreSQL est démarré sur $NUC_HOST ($NUC_HOST:$NUC_PORT)"
    echo "  - Vous avez accès depuis cette machine"
    echo "  - L'authentification est configurée (PGPASSWORD dans .env.nuc si nécessaire)"
    echo ""
    echo "🔧 Test manuel :"
    echo "   psql \"postgresql://$NUC_USER@$NUC_HOST:$NUC_PORT/postgres\" -c \"SELECT 1;\""
    exit 1
fi

echo "✅ Connexion au serveur PostgreSQL réussie"

# Création de la base de données et de l'utilisateur
echo "🏗️  Création de la base de données et de l'utilisateur..."

psql "postgresql://$NUC_USER@$NUC_HOST:$NUC_PORT/postgres" <<EOF
-- Supprimer l'utilisateur s'il existe déjà (pour recréation)
DROP USER IF EXISTS "$DB_USER";

-- Supprimer la base de données si elle existe déjà (pour recréation)
DROP DATABASE IF EXISTS "$DB_NAME";

-- Créer l'utilisateur avec mot de passe
CREATE USER "$DB_USER" WITH PASSWORD '$DB_PASSWORD';

-- Créer la base de données avec l'utilisateur comme propriétaire
CREATE DATABASE "$DB_NAME" OWNER "$DB_USER";

-- Se connecter à la nouvelle base pour configurer les permissions
\c "$DB_NAME"

-- Donner tous les privilèges sur la base de données
GRANT ALL PRIVILEGES ON DATABASE "$DB_NAME" TO "$DB_USER";

-- Donner tous les privilèges sur le schéma public
GRANT ALL ON SCHEMA public TO "$DB_USER";
GRANT CREATE ON SCHEMA public TO "$DB_USER";

-- Donner les privilèges pour créer des tables et des séquences
GRANT ALL ON ALL TABLES IN SCHEMA public TO "$DB_USER";
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO "$DB_USER";

-- Privilèges par défaut pour les futurs objets
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO "$DB_USER";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO "$DB_USER";

-- Permissions spéciales pour Prisma (shadow database)
GRANT CREATE ON DATABASE "$DB_NAME" TO "$DB_USER";

-- Afficher les informations
SELECT 'Base de données créée avec succès' AS status;
\q
EOF

# Construction de l'URL de connexion
DATABASE_URL="postgresql://$DB_USER:$DB_PASSWORD@$NUC_HOST:$NUC_PORT/$DB_NAME"

echo ""
echo "✅ Base de données créée avec succès !"
echo ""
echo "📋 Informations de connexion :"
echo "┌─────────────────────────────────────────────────────────────────────────────────"
echo "│ Base de données : $DB_NAME"
echo "│ Utilisateur     : $DB_USER"
echo "│ Serveur         : $NUC_HOST:$NUC_PORT"
echo "│"
echo "│ 📄 URL de connexion (à copier dans .env.$ENV) :"
echo "│ DATABASE_URL=\"$DATABASE_URL\""
echo "└─────────────────────────────────────────────────────────────────────────────────"
echo ""

# Écrire dans un fichier pour usage automatique
ENV_FILE=".env.${ENV}"
if [ "$ENV" = "dev" ]; then
    ENV_FILE=".env.local"
fi

echo "💾 Écriture dans $ENV_FILE..."

# Créer le fichier d'environnement s'il n'existe pas
if [ ! -f "$ENV_FILE" ]; then
    cp .env.example "$ENV_FILE"
    echo "📄 Fichier $ENV_FILE créé depuis .env.example"
fi

# Mettre à jour ou ajouter DATABASE_URL
if grep -q "^DATABASE_URL=" "$ENV_FILE" 2>/dev/null; then
    # Remplacer la ligne existante (compatible macOS et Linux)
    sed -i.bak "s|^DATABASE_URL=.*|DATABASE_URL=\"$DATABASE_URL\"|" "$ENV_FILE"
    rm -f "$ENV_FILE.bak"
    echo "📝 DATABASE_URL mise à jour dans $ENV_FILE"
else
    # Ajouter la ligne
    echo "" >> "$ENV_FILE"
    echo "# Base de données générée automatiquement" >> "$ENV_FILE"
    echo "DATABASE_URL=\"$DATABASE_URL\"" >> "$ENV_FILE"
    echo "📝 DATABASE_URL ajoutée à $ENV_FILE"
fi

echo ""
echo "🚀 Prochaines étapes :"
echo "1. Vérifiez le fichier $ENV_FILE"
echo "2. Lancez: npx prisma migrate dev --name init"
echo "3. Démarrez votre application avec: npm run dev"
echo ""
echo "🔧 Commandes utiles :"
echo "   psql \"$DATABASE_URL\" -c \"\\dt\"  # Lister les tables"
echo "   npx prisma studio                    # Interface graphique"