# Insights Santé Publique — Cameroun

Synthèse des résultats obtenus par exécution réelle des scripts
`04_analyse_business.R` et `06_stats_descriptives.R` sur les 10 011
consultations nettoyées. Hypothèses détaillées dans `README.md`.

## Vue d'ensemble

- **10 011 consultations** valides après nettoyage, réparties sur 10 régions
  et 150 établissements de santé.
- Âge moyen des patients : **31.7 ans** (médiane 31, écart-type 16.2).
- Coût moyen de traitement : **17.4** (médiane 16.4) — distribution
  quasi symétrique (asymétrie = 0.35), la moyenne est un résumé fiable.
- **82% des consultations** se déroulent avec médicaments disponibles,
  **18% en rupture de stock**.
- **61.6% des patients ne sont pas assurés**, 33.4% sont assurés, 5%
  sans statut renseigné — la couverture d'assurance reste minoritaire.

## Rupture de stock de médicaments : le signal le plus actionable

| Région | Taux de rupture |
|---|---|
| Est | **20.1%** |
| Sud | 19.8% |
| Centre | 19.7% |
| Ouest | 18.7% |
| Nord | 18.0% |
| Extrême-Nord | 17.8% |
| Adamaoua | 17.2% |
| Sud-Ouest | 17.0% |
| Littoral | 16.1% |
| Nord-Ouest | 15.3% |

L'écart Est/Nord-Ouest est de ~5 points — pas un facteur 2, mais un signal
cohérent et exploitable pour prioriser le réapprovisionnement. Vu sous
l'angle des pathologies, la **Diarrhée (19.1%)**, la **Typhoïde (18.8%)** et
le **Diabète (18.6%)** sont les diagnostics les plus touchés par les
ruptures — pathologies pour lesquelles l'accès continu au traitement est
pourtant critique (déshydratation, gestion chronique).

## Coût de traitement par diagnostic

| Diagnostic | Coût moyen |
|---|---|
| Diabète | **29.7** |
| Tuberculose | 28.0 |
| Hypertension | 22.1 |
| Typhoïde | 18.2 |
| Infection Respiratoire | 15.1 |
| Malnutrition | 14.1 |
| Paludisme | 12.1 |
| Anémie | 10.3 |
| Diarrhée | 8.1 |

Les maladies chroniques (Diabète, Hypertension) et la Tuberculose
concentrent les coûts de traitement les plus élevés — cohérent avec des
protocoles de suivi long terme. Le Paludisme et la Diarrhée, pathologies à
très fort volume (>1000 cas chacune), restent peu coûteuses à l'unité mais
représentent un poids financier cumulé important compte tenu du volume.

## Répartition des diagnostics

9 diagnostics, tous entre **10.7% et 11.8%** des cas (Anémie en tête à
11.8%, Hypertension en dernier à 10.7%) — répartition remarquablement
homogène, aucune pathologie ne domine le paysage épidémiologique observé.

## Couverture d'assurance

Entre **33.7%** (Nord) et **36.8%** (Est) de patients assurés selon la
région — écart faible (~3 points), la sous-couverture d'assurance est un
phénomène national plutôt que localisé à certaines régions.

## Démographie

- **42.4%** des patients ont entre 25 et 44 ans (tranche dominante),
  suivis de 15-24 ans (20.4%) et 45-64 ans (18.6%). Les moins de 5 ans
  (3.1%) et les 65 ans et plus (3.0%) sont les tranches les moins
  représentées.
- Genre quasi équilibré : 47.9% femmes, 47.1% hommes, 5% non renseigné.
- Types de consultation également répartis (19.5%-20.5% chacun) : Prenatal,
  Vaccination, Follow-up, Outpatient, Emergency — pas de sur-sollicitation
  d'un type de service en particulier.

## Qualité de la donnée par région

Le taux de diagnostics non renseignés varie de **3.8% (Extrême-Nord)** à
**5.8% (Nord-Ouest)** selon la région — écart modéré mais qui signale des
pratiques de saisie légèrement moins rigoureuses dans certains centres,
point de vigilance pour la formation du personnel de saisie.

---

## Recommandations pour le ministère de la santé

1. **Prioriser le réapprovisionnement en médicaments dans les régions Est,
   Sud et Centre** (taux de rupture 19.7%-20.1%, les 3 plus élevés), en
   particulier pour la Diarrhée, la Typhoïde et le Diabète — pathologies où
   une rupture de traitement a le plus d'impact clinique.
2. **Sécuriser la chaîne d'approvisionnement pour les maladies chroniques**
   (Diabète, Hypertension, Tuberculose) : ce sont les diagnostics les plus
   coûteux à traiter, une rupture de stock y génère un surcoût de reprise
   en charge et un risque clinique élevé (interruption de traitement long
   terme).
3. **Étendre la couverture d'assurance** : avec seulement ~34% de patients
   assurés en moyenne nationale et un écart région faible, l'enjeu est
   structurel (accès à l'assurance) plutôt que localisé — une politique
   nationale d'extension de la couverture aurait un effet uniforme.
4. **Renforcer la formation à la saisie de données dans les centres du
   Nord-Ouest, du Sud et de l'Adamaoua** (régions avec le plus haut taux de
   diagnostics non renseignés), pour fiabiliser le suivi épidémiologique.
5. **Poursuivre le monitoring du volume par pathologie** : la répartition
   très homogène des 9 diagnostics (10.7%-11.8% chacun) constitue une
   baseline utile — un futur écart marqué signalerait une émergence
   épidémique à surveiller.
6. **Utiliser le dashboard Shiny** (`app/app.R`) pour un suivi continu et
   filtrable par région/période/type de consultation par les équipes du
   ministère, sans dépendre de rapports statiques.
