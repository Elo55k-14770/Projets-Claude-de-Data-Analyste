import pandas as pd
import numpy as np
import json

IN = 'afrimarket_dataset_senior.csv'
OUT = 'df_clean.csv'
SUMMARY = 'resultats_clean_summary.json'

print('Loading', IN)
df = pd.read_csv(IN)
initial_shape = df.shape

# Drop exact duplicate rows
df = df.drop_duplicates()
duplicates_removed = initial_shape[0] - df.shape[0]

# Standardize date
df['date_commande'] = pd.to_datetime(df['date_commande'], errors='coerce')
# If any NaT, try alternative formats (none known) - keep as is
na_dates = df['date_commande'].isna().sum()

# Standardize categories
df['categorie'] = df['categorie'].str.strip()
# Normalize common variants
cat_map = {
    'electronique': 'Électronique',
    'Électronique': 'Électronique',
    'Electronique': 'Électronique',
    'Mode': 'Mode',
    'Beauté': 'Beauté',
    'Maison': 'Maison'
}

def norm_cat(x):
    if pd.isna(x):
        return x
    k = x.strip()
    return cat_map.get(k, k.title())

df['categorie'] = df['categorie'].apply(norm_cat)

# Normalize city spellings
city_map = {
    'Kinshassa': 'Kinshasa',
    'kinshasa': 'Kinshasa',
}

def norm_city(x):
    if pd.isna(x):
        return x
    s = x.strip()
    return city_map.get(s, s)

df['ville'] = df['ville'].apply(norm_city)

# Handle negative prices: replace negatives with NaN
neg_prices = (df['prix_unitaire'] < 0).sum()
df.loc[df['prix_unitaire'] < 0, 'prix_unitaire'] = np.nan

# Impute missing or NaN prix_unitaire by median per product or overall median
global_median = df['prix_unitaire'].median()
product_med = df.groupby('nom_produit')['prix_unitaire'].median()

def impute_price(row):
    if pd.notna(row['prix_unitaire']):
        return row['prix_unitaire']
    med = product_med.get(row['nom_produit'], np.nan)
    if pd.notna(med):
        return med
    return global_median

if df['prix_unitaire'].isna().sum() > 0:
    df['prix_unitaire'] = df.apply(impute_price, axis=1)

# Handle quantite zeros: drop rows with quantite == 0
zero_qty = (df['quantite'] == 0).sum()
df = df[df['quantite'] > 0]

# Cap unrealistic remises: negative remises to 0, remises > 0.5 set to 0.5
neg_remises = (df['remise'] < 0).sum()
df.loc[df['remise'] < 0, 'remise'] = 0
large_remises = (df['remise'] > 0.5).sum()
df.loc[df['remise'] > 0.5, 'remise'] = 0.5

# Standardize statut_commande case
df['statut_commande'] = df['statut_commande'].str.strip().str.lower()

# Feature engineering
# chiffre_affaires
df['chiffre_affaires'] = df['prix_unitaire'] * df['quantite'] * (1 - df['remise'])
# marge_brute (estimation): 40% of CA
df['marge_brute_est'] = df['chiffre_affaires'] * 0.4
# profit_net_est = marge_brute - cout_livraison - cout_marketing
# ensure numeric exists for cout_marketing
if 'cout_marketing' not in df.columns:
    df['cout_marketing'] = 0

df['profit_net_est'] = df['marge_brute_est'] - df['cout_livraison'] - df['cout_marketing']
# mois
if 'date_commande' in df.columns:
    df['mois'] = df['date_commande'].dt.to_period('M').astype(str)
else:
    df['mois'] = ''
# indicateur_retour
df['indicateur_retour'] = np.where(df['statut_commande'] == 'retournée', 1, 0)
# nombre_commandes_par_client
nb_cmd = df.groupby('id_client')['id_commande'].nunique()
# Merge back
df = df.merge(nb_cmd.rename('nombre_commandes_par_client'), on='id_client', how='left')
# valeur_vie_client (simplifiée) - total CA per client
clv = df.groupby('id_client')['chiffre_affaires'].sum()
df = df.merge(clv.rename('CLV_simplifie'), on='id_client', how='left')

# Save clean df
print('Saving', OUT)
df.to_csv(OUT, index=False)

summary = {
    'initial_shape': initial_shape,
    'after_dedup_shape': [int(df.shape[0]), int(df.shape[1])],
    'duplicates_removed': int(duplicates_removed),
    'na_dates': int(na_dates),
    'neg_prices_replaced': int(neg_prices),
    'zero_quantity_removed': int(zero_qty),
    'neg_remises_corrected': int(neg_remises),
    'large_remises_capped': int(large_remises),
}

with open(SUMMARY, 'w', encoding='utf-8') as f:
    json.dump(summary, f, indent=2, ensure_ascii=False)

print('Saved summary to', SUMMARY)
print('Done')
