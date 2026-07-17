import os
import json
import sys
import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd
import numpy as np

sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))
from data_pipeline import get_full_dataset

BASE = os.path.dirname(os.path.dirname(__file__))
FIG_DIR = os.path.join(BASE, "figures")
os.makedirs(FIG_DIR, exist_ok=True)

def save_kpis(df, out_json):
    est_livree = df['statut_commande'] == 'Livrée'
    n_total = len(df)
    n_livree = est_livree.sum()
    ca_total = df['ca_realise'].sum()
    profit_total = df['profit_net_estime'].sum()
    panier_moyen = df.loc[est_livree, 'chiffre_affaires'].mean() if n_livree>0 else 0
    taux_annulation = (df['statut_commande'] == 'Annulée').mean()
    taux_retour = (df['statut_commande'] == 'Retournée').mean()

    kpis = {
        'n_total': int(n_total),
        'n_livree': int(n_livree),
        'ca_total': float(ca_total),
        'profit_total': float(profit_total),
        'panier_moyen': float(panier_moyen),
        'taux_annulation_pct': float(taux_annulation*100),
        'taux_retour_pct': float(taux_retour*100),
    }
    with open(out_json, 'w', encoding='utf-8') as f:
        json.dump(kpis, f, indent=2, ensure_ascii=False)
    return kpis

def plot_global(df):
    FIG = os.path.join(FIG_DIR, '01_performance_globale.png')
    est_livree = df['statut_commande'] == 'Livrée'
    ca_total = df['ca_realise'].sum()
    profit_total = df['profit_net_estime'].sum()

    fig, axes = plt.subplots(1,2, figsize=(12,5))
    statut_counts = df['statut_commande'].value_counts()
    axes[0].pie(statut_counts, labels=statut_counts.index, autopct='%1.1f%%')
    axes[0].set_title('Répartition des commandes par statut')

    axes[1].bar(['CA réalisé','Profit net estimé'], [ca_total, profit_total], color=['#4C72B0','#55A868'])
    axes[1].set_title('CA réalisé vs Profit net estimé')
    plt.tight_layout()
    fig.savefig(FIG, dpi=150)
    plt.close(fig)

def plot_category(df):
    FIG = os.path.join(FIG_DIR, '02_analyse_categorie.png')
    cat_stats = df.groupby('categorie').agg(ca=('ca_realise','sum'), marge=('marge_brute_estimee','sum'), taux_retour=('indicateur_retour','mean'))
    cat_stats['taux_retour'] = cat_stats['taux_retour']*100
    fig, axes = plt.subplots(2,2, figsize=(12,10))
    sns.barplot(x=cat_stats.index, y=cat_stats['ca'], ax=axes[0,0])
    axes[0,0].set_title('CA par catégorie')
    sns.barplot(x=cat_stats.index, y=cat_stats['marge'], ax=axes[0,1])
    axes[0,1].set_title('Marge brute estimée')
    sns.barplot(x=cat_stats.index, y=cat_stats['taux_retour'], ax=axes[1,0])
    axes[1,0].set_title('Taux de retour (%)')
    evolution = df.groupby(['mois','categorie'])['ca_realise'].sum().reset_index()
    sns.lineplot(data=evolution, x='mois', y='ca_realise', hue='categorie', marker='o', ax=axes[1,1])
    axes[1,1].set_title('Évolution mensuelle du CA par catégorie')
    plt.tight_layout()
    fig.savefig(FIG, dpi=150)
    plt.close(fig)

def plot_geo(df):
    FIG1 = os.path.join(FIG_DIR, '03_analyse_geo_ca_profit.png')
    ville_stats = df.groupby('ville').agg(ca=('ca_realise','sum'), profit=('profit_net_estime','sum')).sort_values('ca', ascending=False)
    fig, axes = plt.subplots(1,2, figsize=(12,6))
    sns.barplot(y=ville_stats.index, x=ville_stats['ca'], ax=axes[0])
    axes[0].set_title('CA par ville')
    sns.barplot(y=ville_stats.index, x=ville_stats['profit'], ax=axes[1])
    axes[1].set_title('Profit net estimé par ville')
    plt.tight_layout()
    fig.savefig(FIG1, dpi=150)
    plt.close(fig)

    FIG2 = os.path.join(FIG_DIR, '04_heatmap_ville_mois.png')
    pivot = df.pivot_table(index='ville', columns='mois', values='ca_realise', aggfunc='sum', fill_value=0)
    fig, ax = plt.subplots(figsize=(12,7))
    sns.heatmap(pivot, annot=False, cmap='YlGnBu', ax=ax)
    ax.set_title('CA mensuel par ville')
    plt.tight_layout()
    fig.savefig(FIG2, dpi=150)
    plt.close(fig)

def plot_marketing(df):
    FIG1 = os.path.join(FIG_DIR, '05_roi_canal.png')
    canal_stats = df.groupby('canal_marketing').agg(ca=('ca_realise','sum'), cout_marketing=('cout_marketing','sum'))
    canal_stats['roi'] = (canal_stats['ca'] - canal_stats['cout_marketing'])/canal_stats['cout_marketing']
    fig, ax = plt.subplots(figsize=(10,5))
    sns.barplot(x=canal_stats.index, y=canal_stats['roi'], ax=ax)
    ax.set_title('ROI par canal marketing')
    plt.xticks(rotation=30)
    plt.tight_layout()
    fig.savefig(FIG1, dpi=150)
    plt.close(fig)

def plot_clients(df):
    FIG = os.path.join(FIG_DIR, '07_pareto_clients.png')
    clv = df.groupby('id_client')['ca_realise'].sum().sort_values(ascending=False)
    fig, ax = plt.subplots(figsize=(10,5))
    ax.plot(np.arange(1, len(clv)+1), clv.cumsum()/clv.sum()*100)
    ax.set_title('Courbe Pareto - % cumulé du CA par clients')
    ax.set_xlabel('Clients (rang)')
    ax.set_ylabel('% cumulé du CA')
    plt.tight_layout()
    fig.savefig(FIG, dpi=150)
    plt.close(fig)

def main():
    base_csv = os.path.join(os.path.dirname(__file__), '..', 'afrimarket_dataset_senior.csv')
    _, audit, _, df = get_full_dataset(base_csv)
    out_kpis = os.path.join(os.path.dirname(__file__), '..', 'resultats_analyses_kpis.json')
    kpis = save_kpis(df, out_kpis)
    plot_global(df)
    plot_category(df)
    plot_geo(df)
    plot_marketing(df)
    plot_clients(df)
    print('Analyses générées, figures sauvegardées dans', FIG_DIR)

if __name__ == '__main__':
    main()
