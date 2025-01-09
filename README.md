# 🏦 MultiSig Wallet Smart Contract

> Un contrat intelligent de portefeuille multi-signatures sécurisé et flexible développé avec Solidity et Foundry.

## ✨ Fonctionnalités

- 🔐 Minimum 3 signataires requis
- ✅ 2 validations obligatoires pour chaque transaction
- 📝 Soumission de transactions par les signataires
- 👍 Validation et révocation des transactions
- 👥 Gestion dynamique des signataires (ajout/retrait)
- 🧪 Tests complets avec couverture 100%
- 📚 Documentation Natspec complète

## 🛠 Technologies Utilisées

- **Solidity** - v0.8.19
- **Foundry** - Framework de test et déploiement
- **Natspec** - Documentation du code

## 🚀 Installation

1. **Cloner le repo**
```bash
git clone https://github.com/0xNaxzerrr/MultiSigWallet
cd MultiSigWallet
```

2. **Installer les dépendances**
```bash
forge install
```

3. **Compiler les contrats**
```bash
forge build
```

## 🧪 Tests

Pour exécuter la suite de tests complète :
```bash
forge test
```

Pour voir la couverture de code :
```bash
forge coverage
```

## 📦 Déploiement

1. Créer un fichier `.env` avec votre clé privée :
```bash
echo "PRIVATE_KEY=votre_clé_privée" > .env
```

2. Déployer sur le réseau de votre choix :
```bash
forge script script/DeployMultiSigWallet.s.sol --rpc-url <votre_rpc_url> --broadcast
```

## 📖 Documentation

### Structure du Contrat

Le contrat comporte plusieurs composants clés :

- **Transaction** : Structure contenant les détails d'une transaction
  - `to` : Adresse de destination
  - `value` : Montant d'ETH
  - `data` : Données de la transaction
  - `executed` : État d'exécution
  - `numConfirmations` : Nombre de confirmations

- **Signataires** : Gestion des propriétaires du wallet
  - Minimum 3 signataires
  - 2 confirmations requises pour l'exécution

### Fonctions Principales

#### 📤 `submitTransaction`
Permet à un signataire de soumettre une nouvelle transaction.

#### ✅ `confirmTransaction`
Permet à un signataire de confirmer une transaction en attente.

#### ❌ `revokeConfirmation`
Permet à un signataire de révoquer sa confirmation.

#### 👥 `addSigner`
Ajoute un nouveau signataire au wallet.

#### 🚫 `removeSigner`
Retire un signataire existant (tout en maintenant le minimum requis).

## 🔒 Sécurité

- Vérifications multiples de sécurité
- Modifieurs de contrôle d'accès
- Protection contre la réentrance
- Validation des adresses nulles

## 📜 Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

## 🤝 Contribution

Les contributions sont les bienvenues ! N'hésitez pas à :

1. Fork le projet
2. Créer une branche pour votre fonctionnalité
3. Commit vos changements
4. Push sur votre fork
5. Ouvrir une Pull Request
