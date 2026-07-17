# -*- coding: utf-8 -*-
"""
Dashboard interactif Streamlit — AfriMarket
Lancer avec : streamlit run dashboard_afrimarket.py
"""

import os
import sys

import streamlit as st
import pandas as pd
import numpy as np
import plotly.express as px
import plotly.graph_objects as go

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, BASE_DIR)

from data_pipeline import get_full_dataset

st.set_page_config(page_title="AfriMarket — Dashboard Stratégique", layout="wide", page_icon="📊")


@st.cache_data
def charger_donnees():
    csv_path = os.path.join(BASE_DIR, "afrimarket_dataset_senior.csv")
    df_raw, audit, df_clean, df = get_full_dataset(csv_path)
    return df_raw, audit, df_clean, df


df_raw, audit, df_clean, df_full = charger_donnees()

# ---------------------------------------------------------------------------
# SIDEBAR - FILTRES
# ---------------------------------------------------------------------------
st.sidebar.title("📊 AfriMarket")
st.sidebar.caption("Dashboard stratégique — Juillet à Décembre 2025")
st.sidebar.markdown("---")
st.sidebar.header("Filtres")

mois_dispo = sorted(df_full["mois"].unique())
villes_dispo = sorted(df_full["ville"].unique())
categories_dispo = sorted(df_full["categorie"].unique())
canaux_dispo = sorted(df_full["canal_marketing"].unique())
statuts_dispo = sorted(df_full["statut_commande"].unique())

f_mois = st.sidebar.multiselect("Mois", mois_dispo, default=mois_dispo)
f_ville = st.sidebar.multiselect("Ville", villes_dispo, default=villes_dispo)
f_categorie = st.sidebar.multiselect("Catégorie", categories_dispo, default=categories_dispo)
f_canal = st.sidebar.multiselect("Canal marketing", canaux_dispo, default=canaux_dispo)
f_statut = st.sidebar.multiselect("Statut de commande", statuts_dispo, default=statuts_dispo)

df = df_full[
    df_full["mois"].isin(f_mois)
    & df_full["ville"].isin(f_ville)
    & df_full["categorie"].isin(f_categorie)
    & df_full["canal_marketing"].isin(f_canal)
    & df_full["statut_commande"].isin(f_statut)
]

with st.sidebar.expander("ℹ️ Qualité des données (audit)"):
    st.write(f"Lignes brutes : **{audit['n_lignes']:,}**")
    st.write(f"Doublons supprimés : **{audit['doublons_id_commande']}**")
    st.write(f"Villes corrigées : **{audit['villes_mal_orthographiees']}**")
    st.write(f"Catégories corrigées : **{audit['categories_incoherentes']}**")
    st.write(f"Statuts corrigés : **{audit['statuts_incoherents']}**")
    st.write(f"Remises négatives corrigées : **{audit['remises_negatives']}**")
    st.write(f"Prix aberrants corrigés : **{audit['prix_negatifs_ou_nuls']}**")
    st.write(f"Quantités nulles supprimées : **{audit['quantites_nulles']}**")
    st.write(f"Lignes finales exploitées : **{len(df_clean):,}**")

if df.empty:
    st.warning("Aucune donnée ne correspond aux filtres sélectionnés.")
    st.stop()

# ---------------------------------------------------------------------------
# EN-TETE + KPIs
# ---------------------------------------------------------------------------
st.title("Dashboard Stratégique — AfriMarket")
st.caption("E-commerce panafricain • Électronique, Mode, Beauté, Maison")

est_livree = df["statut_commande"] == "Livrée"
ca_total = df["ca_realise"].sum()
profit_total = df["profit_net_estime"].sum()
panier_moyen = df.loc[est_livree, "chiffre_affaires"].mean() if est_livree.any() else 0
taux_annulation = (df["statut_commande"] == "Annulée").mean() * 100
taux_retour = (df["statut_commande"] == "Retournée").mean() * 100
nb_clients = df["id_client"].nunique()

c1, c2, c3, c4, c5, c6 = st.columns(6)
c1.metric("CA réalisé", f"{ca_total:,.0f}")
c2.metric("Profit net estimé", f"{profit_total:,.0f}")
c3.metric("Panier moyen", f"{panier_moyen:,.0f}")
c4.metric("Taux d'annulation", f"{taux_annulation:.1f}%")
c5.metric("Taux de retour", f"{taux_retour:.1f}%")
c6.metric("Clients uniques", f"{nb_clients:,}")

st.markdown("---")

tab1, tab2, tab3, tab4, tab5 = st.tabs([
    "🌍 Vue d'ensemble", "🏷️ Catégories", "📍 Villes", "📣 Marketing", "👥 Clients"
])

# ---------------------------------------------------------------------------
# TAB 1 - VUE D'ENSEMBLE
# ---------------------------------------------------------------------------
with tab1:
    col1, col2 = st.columns(2)

    with col1:
        statut_counts = df["statut_commande"].value_counts().reset_index()
        statut_counts.columns = ["statut", "n"]
        fig = px.pie(statut_counts, names="statut", values="n", title="Répartition des commandes par statut",
                     color_discrete_sequence=px.colors.qualitative.Set2)
        st.plotly_chart(fig, use_container_width=True)

    with col2:
        evolution = df.groupby("mois").agg(ca=("ca_realise", "sum"), profit=("profit_net_estime", "sum")).reset_index()
        fig = go.Figure()
        fig.add_bar(x=evolution["mois"], y=evolution["ca"], name="CA réalisé")
        fig.add_scatter(x=evolution["mois"], y=evolution["profit"], name="Profit net estimé", mode="lines+markers", yaxis="y")
        fig.update_layout(title="Évolution mensuelle du CA et du profit", xaxis_title="Mois")
        st.plotly_chart(fig, use_container_width=True)

    st.subheader("Détail des commandes")
    st.dataframe(
        df[["id_commande", "date_commande", "ville", "categorie", "statut_commande",
            "chiffre_affaires", "ca_realise", "profit_net_estime", "canal_marketing"]].sort_values("date_commande", ascending=False).head(200),
        use_container_width=True,
    )

# ---------------------------------------------------------------------------
# TAB 2 - CATEGORIES
# ---------------------------------------------------------------------------
with tab2:
    st.subheader("Performance par catégorie")
    st.caption("Question stratégique : quelle catégorie doit être priorisée ou optimisée ?")

    cat_stats = df.groupby("categorie").agg(
        ca=("ca_realise", "sum"),
        marge=("marge_brute_estimee", "sum"),
        profit=("profit_net_estime", "sum"),
        n_commandes=("id_commande", "count"),
        taux_retour=("indicateur_retour", "mean"),
    ).reset_index().sort_values("ca", ascending=False)
    cat_stats["taux_retour"] = cat_stats["taux_retour"] * 100

    col1, col2 = st.columns(2)
    with col1:
        fig = px.bar(cat_stats, x="categorie", y="ca", color="categorie", title="CA par catégorie",
                     text_auto=".2s")
        st.plotly_chart(fig, use_container_width=True)
    with col2:
        fig = px.bar(cat_stats, x="categorie", y="marge", color="categorie", title="Marge brute estimée par catégorie",
                     text_auto=".2s")
        st.plotly_chart(fig, use_container_width=True)

    col3, col4 = st.columns(2)
    with col3:
        fig = px.bar(cat_stats, x="categorie", y="taux_retour", color="categorie",
                     title="Taux de retour par catégorie (%)", text_auto=".1f")
        st.plotly_chart(fig, use_container_width=True)
    with col4:
        evolution_cat = df.groupby(["mois", "categorie"])["ca_realise"].sum().reset_index()
        fig = px.line(evolution_cat, x="mois", y="ca_realise", color="categorie", markers=True,
                      title="Évolution mensuelle du CA par catégorie")
        st.plotly_chart(fig, use_container_width=True)

    st.dataframe(cat_stats, use_container_width=True)

# ---------------------------------------------------------------------------
# TAB 3 - VILLES
# ---------------------------------------------------------------------------
with tab3:
    st.subheader("Performance géographique")
    st.caption("Question stratégique : où devons-nous investir davantage ?")

    ville_stats = df.groupby("ville").agg(
        ca=("ca_realise", "sum"),
        profit=("profit_net_estime", "sum"),
        n_commandes=("id_commande", "count"),
        taux_annulation=("statut_commande", lambda s: (s == "Annulée").mean() * 100),
    ).reset_index().sort_values("ca", ascending=False)

    col1, col2 = st.columns(2)
    with col1:
        fig = px.bar(ville_stats, y="ville", x="ca", orientation="h", title="CA par ville", color="ca",
                     color_continuous_scale="Blues")
        st.plotly_chart(fig, use_container_width=True)
    with col2:
        fig = px.bar(ville_stats, y="ville", x="taux_annulation", orientation="h",
                     title="Taux d'annulation par ville (%)", color="taux_annulation",
                     color_continuous_scale="Reds")
        st.plotly_chart(fig, use_container_width=True)

    pivot_vm = df.pivot_table(index="ville", columns="mois", values="ca_realise", aggfunc="sum", fill_value=0)
    fig = px.imshow(pivot_vm, text_auto=",.0f", aspect="auto", color_continuous_scale="YlGnBu",
                     title="CA mensuel par ville (heatmap)")
    st.plotly_chart(fig, use_container_width=True)

    if pivot_vm.shape[1] >= 2:
        croissance = ((pivot_vm.iloc[:, -1] - pivot_vm.iloc[:, 0]) / pivot_vm.iloc[:, 0].replace(0, np.nan) * 100)
        croissance = croissance.rename("croissance_pct").sort_values(ascending=False)
        st.subheader(f"Croissance du CA : {pivot_vm.columns[0]} → {pivot_vm.columns[-1]}")
        fig = px.bar(croissance.reset_index(), x="ville", y="croissance_pct",
                     title="Croissance mensuelle du CA par ville (%)")
        st.plotly_chart(fig, use_container_width=True)

    st.dataframe(ville_stats, use_container_width=True)

# ---------------------------------------------------------------------------
# TAB 4 - MARKETING
# ---------------------------------------------------------------------------
with tab4:
    st.subheader("Performance marketing")
    st.caption("ROI = (Revenus − Coût marketing) / Coût marketing • Question stratégique : quel canal mérite plus de budget ?")

    canal_stats = df.groupby("canal_marketing").agg(
        ca=("ca_realise", "sum"),
        cout_marketing=("cout_marketing", "sum"),
        n_commandes=("id_commande", "count"),
    ).reset_index()
    canal_stats["roi"] = (canal_stats["ca"] - canal_stats["cout_marketing"]) / canal_stats["cout_marketing"]

    commandes_par_client_full = df.groupby("id_client")["id_commande"].nunique()
    retention = df.groupby("canal_marketing")["id_client"].apply(
        lambda clients: (clients.map(commandes_par_client_full) > 1).mean() * 100
    )
    canal_stats["taux_retention_pct"] = canal_stats["canal_marketing"].map(retention)
    canal_stats = canal_stats.sort_values("roi", ascending=False)

    col1, col2 = st.columns(2)
    with col1:
        fig = px.bar(canal_stats, x="canal_marketing", y="roi", color="roi", color_continuous_scale="RdYlGn",
                     title="ROI par canal marketing", text_auto=".2f")
        st.plotly_chart(fig, use_container_width=True)
    with col2:
        fig = px.bar(canal_stats, x="canal_marketing", y="cout_marketing", title="Coût marketing total par canal",
                     color="canal_marketing")
        st.plotly_chart(fig, use_container_width=True)

    fig = px.bar(canal_stats, x="canal_marketing", y="taux_retention_pct", title="Taux de rétention par canal (%)",
                 color="canal_marketing")
    st.plotly_chart(fig, use_container_width=True)

    st.dataframe(canal_stats, use_container_width=True)

# ---------------------------------------------------------------------------
# TAB 5 - CLIENTS
# ---------------------------------------------------------------------------
with tab5:
    st.subheader("Analyse clients")
    st.caption("Question stratégique : comment améliorer la rétention ?")

    commandes_par_client = df.groupby("id_client")["id_commande"].nunique()
    nb_clients_total = df["id_client"].nunique()
    pct_recurrents = (commandes_par_client > 1).mean() * 100

    colA, colB = st.columns(2)
    colA.metric("Nombre total de clients", f"{nb_clients_total:,}")
    colB.metric("% clients récurrents (>1 commande)", f"{pct_recurrents:.1f}%")

    clv_par_client = df.groupby("id_client")["ca_realise"].sum().sort_values(ascending=False)
    cum_ca_pct = (clv_par_client.cumsum() / clv_par_client.sum() * 100) if clv_par_client.sum() > 0 else clv_par_client.cumsum()
    cum_clients_pct = np.arange(1, len(clv_par_client) + 1) / len(clv_par_client) * 100

    fig = go.Figure()
    fig.add_bar(x=list(range(1, len(clv_par_client) + 1)), y=clv_par_client.values, name="CA par client")
    fig.add_scatter(x=list(range(1, len(clv_par_client) + 1)), y=cum_ca_pct.values, name="% cumulé du CA",
                     mode="lines", yaxis="y2")
    fig.update_layout(
        title="Analyse Pareto (80/20) des clients",
        yaxis=dict(title="CA par client"),
        yaxis2=dict(title="% cumulé du CA", overlaying="y", side="right", range=[0, 105]),
    )
    st.plotly_chart(fig, use_container_width=True)

    col1, col2 = st.columns(2)
    with col1:
        st.markdown("**Top 10 clients (valeur vie client)**")
        top10 = clv_par_client.head(10).to_frame("valeur_vie_client").reset_index()
        top10["nombre_commandes"] = top10["id_client"].map(commandes_par_client)
        top10["segment"] = top10["id_client"].map(df.groupby("id_client")["segment_client"].first())
        st.dataframe(top10, use_container_width=True)

    with col2:
        st.markdown("**Segmentation client (CLV)**")
        segment_par_client = df.groupby("id_client")["segment_client"].first()
        seg_summary = df.groupby("id_client")["valeur_vie_client"].first().groupby(segment_par_client).agg(
            ["count", "mean", "sum"]
        )
        seg_summary.columns = ["nb_clients", "clv_moyenne", "clv_totale"]
        fig = px.pie(seg_summary.reset_index(), names="segment_client", values="nb_clients",
                     title="Répartition des clients par segment", color_discrete_sequence=px.colors.qualitative.Set2)
        st.plotly_chart(fig, use_container_width=True)
        st.dataframe(seg_summary, use_container_width=True)

st.markdown("---")
st.caption("Dashboard généré à partir de df_clean (données auditées et nettoyées) — voir le notebook Analyse_AfriMarket.ipynb pour la méthodologie complète.")
