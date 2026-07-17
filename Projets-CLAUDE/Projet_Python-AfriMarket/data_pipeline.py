# -*- coding: utf-8 -*-
"""
Module de préparation des données AfriMarket.
Utilisé à la fois par le notebook d'analyse et le dashboard Streamlit,
afin de garantir une logique métier identique partout (source unique de vérité).
"""

import pandas as pd
import numpy as np

# ---------------------------------------------------------------------------
# Hypothèses métier (à défaut de coût matière réel dans le dataset)
# Taux de marge brute estimés par catégorie, cohérents avec les pratiques
# e-commerce : électronique = marge faible (marché concurrentiel), beauté = marge élevée.
# ---------------------------------------------------------------------------
TAUX_MARGE_CATEGORIE = {
    "Électronique": 0.12,
    "Mode": 0.45,
    "Beauté": 0.55,
    "Maison": 0.30,
}

VILLE_CORRECTIONS = {
    "Kinshassa": "Kinshasa",
}

CATEGORIE_CORRECTIONS = {
    "electronique": "Électronique",
}

STATUT_CORRECTIONS = {
    "retournée": "Retournée",
    "Livrée": "Livrée",
    "Annulée": "Annulée",
}

PRIX_SENTINELLE_ERREUR = -50.00  # valeur d'erreur de saisie récurrente (identifiée à l'audit)


def load_raw(path: str) -> pd.DataFrame:
    """Charge le dataset brut depuis le CSV source."""
    return pd.read_csv(path)


def audit_report(df: pd.DataFrame) -> dict:
    """Construit un rapport d'audit synthétique des problèmes de qualité détectés."""
    report = {
        "n_lignes": len(df),
        "n_colonnes": df.shape[1],
        "valeurs_manquantes": int(df.isnull().sum().sum()),
        "doublons_id_commande": int(df.duplicated(subset=["id_commande"]).sum()),
        "villes_mal_orthographiees": int(df["ville"].isin(VILLE_CORRECTIONS.keys()).sum()),
        "categories_incoherentes": int(df["categorie"].isin(CATEGORIE_CORRECTIONS.keys()).sum()),
        "statuts_incoherents": int(df["statut_commande"].str.islower().sum()),
        "remises_negatives": int((df["remise"] < 0).sum()),
        "prix_negatifs_ou_nuls": int((df["prix_unitaire"] <= 0).sum()),
        "quantites_nulles": int((df["quantite"] == 0).sum()),
    }
    return report


def clean_data(df: pd.DataFrame) -> pd.DataFrame:
    """
    Applique le pipeline de nettoyage complet et retourne df_clean.

    Étapes :
      1. Suppression des doublons exacts (id_commande dupliqué)
      2. Standardisation des dates (datetime)
      3. Correction des villes mal orthographiées
      4. Uniformisation des catégories (casse / accents)
      5. Uniformisation des statuts de commande
      6. Correction des remises négatives (erreur de signe -> valeur absolue)
      7. Traitement des prix aberrants (sentinelle -50 -> médiane catégorie ;
         autres négatifs -> valeur absolue, probable erreur de signe)
      8. Suppression des commandes à quantité nulle (non exploitables, non imputables)
    """
    d = df.copy()

    # 1. Doublons exacts
    d = d.drop_duplicates(subset=["id_commande"], keep="first")

    # 2. Dates
    d["date_commande"] = pd.to_datetime(d["date_commande"], format="%Y-%m-%d", errors="coerce")

    # 3. Villes
    d["ville"] = d["ville"].replace(VILLE_CORRECTIONS)

    # 4. Catégories
    d["categorie"] = d["categorie"].replace(CATEGORIE_CORRECTIONS)

    # 5. Statuts (normalisation de casse : première lettre majuscule)
    d["statut_commande"] = d["statut_commande"].str.strip().str.capitalize()

    # 6. Remises négatives : toutes exactement -0.10 -> erreur de signe -> valeur absolue
    d["remise"] = d["remise"].abs()
    d["remise"] = d["remise"].clip(0, 0.3)  # garde-fou cohérent avec la politique de remise (0-30%)

    # 7. Prix aberrants
    #    a) sentinelle d'erreur de saisie (-50.00, répétée ~610 fois) -> imputée par la médiane de la catégorie
    is_sentinelle = np.isclose(d["prix_unitaire"], PRIX_SENTINELLE_ERREUR)
    medianes_categorie = d.loc[~is_sentinelle & (d["prix_unitaire"] > 0)].groupby("categorie")["prix_unitaire"].median()
    d.loc[is_sentinelle, "prix_unitaire"] = d.loc[is_sentinelle, "categorie"].map(medianes_categorie)
    #    b) autres négatifs isolés -> probable inversion de signe -> valeur absolue
    d["prix_unitaire"] = d["prix_unitaire"].abs()

    # 8. Quantités nulles : une commande facturée ne peut porter sur 0 article ;
    #    non imputable de façon fiable -> suppression (~6% des lignes)
    d = d[d["quantite"] > 0]

    d = d.reset_index(drop=True)
    return d


def engineer_features(d: pd.DataFrame) -> pd.DataFrame:
    """
    Ajoute les variables métier (feature engineering) à df_clean :
      - chiffre_affaires (brut, valeur de la commande hors statut)
      - ca_realise (CA effectivement encaissé : 0 si Annulée/Retournée)
      - marge_brute_estimee, profit_net_estime
      - mois
      - indicateur_retour
      - nombre_commandes_par_client
      - valeur_vie_client (CLV simplifiée)
      - segment_client
    """
    d = d.copy()

    # Chiffre d'affaires brut de la ligne de commande (avant prise en compte du statut)
    d["chiffre_affaires"] = d["prix_unitaire"] * d["quantite"] * (1 - d["remise"])

    d["mois"] = d["date_commande"].dt.to_period("M").astype(str)
    d["indicateur_retour"] = (d["statut_commande"] == "Retournée").astype(int)

    taux_marge = d["categorie"].map(TAUX_MARGE_CATEGORIE).fillna(0.30)

    # CA réalisé : seules les commandes livrées génèrent un revenu net définitif.
    # Les commandes annulées ne génèrent aucun revenu ; les commandes retournées sont remboursées (CA = 0)
    # mais les coûts déjà engagés (livraison, marketing) restent une perte sèche.
    est_livree = d["statut_commande"] == "Livrée"
    est_annulee = d["statut_commande"] == "Annulée"
    est_retournee = d["statut_commande"] == "Retournée"

    d["ca_realise"] = np.where(est_livree, d["chiffre_affaires"], 0.0)
    d["marge_brute_estimee"] = np.where(est_livree, d["chiffre_affaires"] * taux_marge, 0.0)

    d["profit_net_estime"] = np.select(
        [est_livree, est_annulee, est_retournee],
        [
            d["marge_brute_estimee"] - d["cout_livraison"] - d["cout_marketing"],
            -d["cout_marketing"],
            -(d["cout_livraison"] + d["cout_marketing"]),
        ],
        default=0.0,
    )

    # Fréquence client et CLV simplifiée (sur l'ensemble de la période de 6 mois observée)
    d["nombre_commandes_par_client"] = d.groupby("id_client")["id_commande"].transform("count")
    d["valeur_vie_client"] = d.groupby("id_client")["ca_realise"].transform("sum")

    # Segmentation simple par valeur (CLV)
    clv_client = d.groupby("id_client")["valeur_vie_client"].first()
    q80 = clv_client.quantile(0.80)
    q50 = clv_client.quantile(0.50)

    def segmenter(clv):
        if clv >= q80:
            return "VIP"
        elif clv >= q50:
            return "Régulier"
        else:
            return "Occasionnel"

    segment_map = clv_client.apply(segmenter)
    d["segment_client"] = d["id_client"].map(segment_map)

    return d


def get_full_dataset(raw_csv_path: str):
    """Pipeline complet : chargement -> audit -> nettoyage -> feature engineering."""
    df_raw = load_raw(raw_csv_path)
    audit = audit_report(df_raw)
    df_clean = clean_data(df_raw)
    df_features = engineer_features(df_clean)
    return df_raw, audit, df_clean, df_features
