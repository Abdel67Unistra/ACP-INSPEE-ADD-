# ============================================================================
# GÉNÉRATION DES GRAPHIQUES POUR LE README
# Script pour sauvegarder tous les plots en PNG
# ============================================================================

# Chargement des packages
library(FactoMineR)
library(factoextra)
library(corrplot)
library(ggplot2)
library(psych)

# Chemin de sortie des images
output_dir <- "/Users/cheriet/Documents/ACPCCM1/images/"

# ============================================================================
# CHARGEMENT ET PRÉPARATION DES DONNÉES
# ============================================================================

insee <- read.csv(
  "/Users/cheriet/Documents/ACPCCM1/base_cc_comparateur.csv",
  sep = ";",
  stringsAsFactors = FALSE,
  na.strings = c("", "NA", "s")
)

# Convertir SUPERF avec point décimal
insee$SUPERF <- as.numeric(gsub(",", ".", insee$SUPERF))
insee$MED21 <- as.numeric(gsub(",", ".", insee$MED21))
insee$TP6021 <- as.numeric(gsub(",", ".", insee$TP6021))
insee$PIMP21 <- as.numeric(gsub(",", ".", insee$PIMP21))

# Création des variables dérivées
insee$densite_pop <- insee$P22_POP / insee$SUPERF
insee$taux_natalite <- (insee$NAIS1621 / 6) / insee$P22_POP * 1000
insee$taux_mortalite <- (insee$DECE1621 / 6) / insee$P22_POP * 1000
insee$taux_res_secondaires <- insee$P22_RSECOCC / insee$P22_LOG * 100
insee$taux_logements_vacants <- insee$P22_LOGVAC / insee$P22_LOG * 100
insee$taux_proprietaires <- insee$P22_RP_PROP / insee$P22_RP * 100
insee$taux_chomage <- insee$P22_CHOM1564 / insee$P22_ACT1564 * 100
insee$pct_agriculture <- insee$ETAZ23 / insee$ETTOT23 * 100
insee$pct_industrie <- insee$ETBE23 / insee$ETTOT23 * 100
insee$pct_services <- insee$ETGU23 / insee$ETTOT23 * 100

# MED21 et TP6021 sont déjà numériques après la conversion

# On retire TP6021 car trop de NA (secret statistique)
var_quanti <- c(
  "densite_pop", "taux_natalite", "taux_mortalite",
  "taux_res_secondaires", "taux_logements_vacants", "taux_proprietaires",
  "MED21", "taux_chomage",
  "pct_agriculture", "pct_industrie", "pct_services"
)

insee$departement <- substr(insee$CODGEO, 1, 2)
insee$departement <- factor(insee$departement)

df_acp <- insee[, c("CODGEO", var_quanti, "departement")]

# Supprimer les lignes avec des NA ou Inf
df_acp <- df_acp[complete.cases(df_acp[, var_quanti]), ]
df_acp <- df_acp[is.finite(rowSums(df_acp[, var_quanti])), ]

rownames(df_acp) <- df_acp$CODGEO

cat("Nombre de communes après nettoyage:", nrow(df_acp), "\n")

# ============================================================================
# GRAPHIQUE 1: MATRICE DE CORRÉLATION
# ============================================================================

mat.cor <- round(cor(df_acp[, var_quanti], use = "complete.obs"), 3)

png(paste0(output_dir, "01_matrice_correlation.png"), width = 900, height = 800, res = 100)
corrplot(mat.cor, 
         method = "color",
         type = "lower",
         tl.srt = 45,
         tl.col = "black",
         tl.cex = 0.8,
         addCoef.col = "black",
         number.cex = 0.6,
         title = "Matrice de corrélation - 12 variables INSEE",
         mar = c(0, 0, 2, 0))
dev.off()
cat("✓ 01_matrice_correlation.png\n")

# ============================================================================
# ACP
# ============================================================================

df_pca <- df_acp[, var_quanti]
res.acp <- PCA(df_pca, scale.unit = TRUE, ncp = 10, graph = FALSE)

# ============================================================================
# GRAPHIQUE 2: ÉBOULIS DES VALEURS PROPRES
# ============================================================================

png(paste0(output_dir, "02_eboulis_valeurs_propres.png"), width = 800, height = 600, res = 100)
print(fviz_eig(res.acp, 
         addlabels = TRUE,
         ylim = c(0, 35),
         main = "Éboulis des valeurs propres",
         xlab = "Dimensions",
         ylab = "% de variance expliquée",
         barfill = "steelblue",
         barcolor = "steelblue"))
dev.off()
cat("✓ 02_eboulis_valeurs_propres.png\n")

# ============================================================================
# GRAPHIQUE 3: CRITÈRE DU BÂTON BRISÉ
# ============================================================================

if (require(PCDimension)) {
  p <- length(var_quanti)
  bs <- 100 * PCDimension::brokenStick(1:p, p)
  vp <- res.acp$eig[1:p, 2]
  
  png(paste0(output_dir, "03_baton_brise.png"), width = 800, height = 600, res = 100)
  barplot(rbind(vp, bs),
          beside = TRUE,
          legend = c("Inertie (%)", "Bâton brisé"),
          col = c("tomato1", "turquoise3"),
          border = "white",
          main = "Critère du bâton brisé",
          xlab = "Dimensions",
          ylab = "Inertie (%)",
          names.arg = paste0("Dim", 1:p),
          cex.names = 0.7)
  dev.off()
  cat("✓ 03_baton_brise.png\n")
}

# ============================================================================
# GRAPHIQUE 4: CERCLE DES CORRÉLATIONS (basique)
# ============================================================================

png(paste0(output_dir, "04_cercle_correlations.png"), width = 800, height = 800, res = 100)
print(fviz_pca_var(res.acp, 
             col.var = "black",
             repel = TRUE,
             title = "Cercle des corrélations (Dim1-Dim2)") +
  coord_fixed(ratio = 1))
dev.off()
cat("✓ 04_cercle_correlations.png\n")

# ============================================================================
# GRAPHIQUE 5: CERCLE AVEC CONTRIBUTION EN COULEUR
# ============================================================================

png(paste0(output_dir, "05_cercle_contribution.png"), width = 800, height = 800, res = 100)
print(fviz_pca_var(res.acp, 
             col.var = "contrib",
             gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"),
             repel = TRUE,
             title = "Cercle des corrélations - couleur = contribution") +
  coord_fixed(ratio = 1))
dev.off()
cat("✓ 05_cercle_contribution.png\n")

# ============================================================================
# GRAPHIQUE 6: CERCLE AVEC COS² EN COULEUR
# ============================================================================

png(paste0(output_dir, "06_cercle_cos2.png"), width = 800, height = 800, res = 100)
print(fviz_pca_var(res.acp, 
             col.var = "cos2",
             gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"),
             repel = TRUE,
             title = "Cercle des corrélations - couleur = cos²") +
  coord_fixed(ratio = 1))
dev.off()
cat("✓ 06_cercle_cos2.png\n")

# ============================================================================
# GRAPHIQUE 7: CONTRIBUTIONS À L'AXE 1
# ============================================================================

png(paste0(output_dir, "07_contrib_dim1.png"), width = 800, height = 500, res = 100)
print(fviz_contrib(res.acp, 
             choice = "var", 
             axes = 1,
             fill = "steelblue",
             color = "steelblue",
             title = "Contributions des variables à l'axe 1"))
dev.off()
cat("✓ 07_contrib_dim1.png\n")

# ============================================================================
# GRAPHIQUE 8: CONTRIBUTIONS À L'AXE 2
# ============================================================================

png(paste0(output_dir, "08_contrib_dim2.png"), width = 800, height = 500, res = 100)
print(fviz_contrib(res.acp, 
             choice = "var", 
             axes = 2,
             fill = "darkorange",
             color = "darkorange",
             title = "Contributions des variables à l'axe 2"))
dev.off()
cat("✓ 08_contrib_dim2.png\n")

# ============================================================================
# GRAPHIQUE 9: CONTRIBUTIONS AU PLAN 1-2
# ============================================================================

png(paste0(output_dir, "09_contrib_plan12.png"), width = 800, height = 500, res = 100)
print(fviz_contrib(res.acp, 
             choice = "var", 
             axes = 1:2,
             fill = "darkgreen",
             color = "darkgreen",
             title = "Contributions des variables au plan 1-2"))
dev.off()
cat("✓ 09_contrib_plan12.png\n")

# ============================================================================
# GRAPHIQUE 10: COS² DES VARIABLES
# ============================================================================

png(paste0(output_dir, "10_cos2_variables.png"), width = 800, height = 500, res = 100)
print(fviz_cos2(res.acp, 
          choice = "var", 
          axes = 1:2,
          fill = "purple",
          color = "purple",
          title = "Qualité de représentation (cos²) - Plan 1-2"))
dev.off()
cat("✓ 10_cos2_variables.png\n")

# ============================================================================
# GRAPHIQUE 11: NUAGE DES INDIVIDUS (COMMUNES) - COS²
# ============================================================================

png(paste0(output_dir, "11_individus_cos2.png"), width = 900, height = 800, res = 100)
print(fviz_pca_ind(res.acp, 
             col.ind = "cos2",
             gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"),
             pointsize = 0.5,
             title = "Communes colorées par qualité (cos²)") +
  coord_fixed(ratio = 1))
dev.off()
cat("✓ 11_individus_cos2.png\n")

# ============================================================================
# GRAPHIQUE 12: INDIVIDUS BIEN REPRÉSENTÉS (cos² > 0.5)
# ============================================================================

png(paste0(output_dir, "12_individus_selection.png"), width = 900, height = 800, res = 100)
print(fviz_pca_ind(res.acp, 
             col.ind = "cos2",
             gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"),
             select.ind = list(cos2 = 0.5),
             pointsize = 1.5,
             title = "Communes avec cos² > 0.5") +
  coord_fixed(ratio = 1))
dev.off()
cat("✓ 12_individus_selection.png\n")

# ============================================================================
# GRAPHIQUE 13: TOP CONTRIBUTEURS AXE 1
# ============================================================================

png(paste0(output_dir, "13_top_contrib_dim1.png"), width = 800, height = 600, res = 100)
print(fviz_contrib(res.acp, 
             choice = "ind", 
             axes = 1,
             top = 30,
             fill = "steelblue",
             color = "steelblue",
             title = "Top 30 communes contributrices à l'axe 1"))
dev.off()
cat("✓ 13_top_contrib_dim1.png\n")

# ============================================================================
# GRAPHIQUE 14: BIPLOT
# ============================================================================

png(paste0(output_dir, "14_biplot.png"), width = 1000, height = 900, res = 100)
print(fviz_pca_biplot(res.acp, 
                repel = TRUE,
                col.var = "#2E9FDF",
                col.ind = "#696969",
                select.ind = list(cos2 = 0.7),
                pointsize = 1,
                title = "Biplot - communes (cos² > 0.7) et variables") +
  coord_fixed(ratio = 1))
dev.off()
cat("✓ 14_biplot.png\n")

# ============================================================================
# GRAPHIQUE 15: CORRÉLATIONS VARIABLES-AXES (heatmap)
# ============================================================================

png(paste0(output_dir, "15_correlation_axes.png"), width = 700, height = 600, res = 100)
corrplot(res.acp$var$cor[, 1:5], 
         is.corr = FALSE,
         method = "color",
         addCoef.col = "black",
         number.cex = 0.7,
         tl.cex = 0.8,
         cl.cex = 0.7,
         title = "Corrélations variables-axes (Dim 1 à 5)",
         mar = c(0, 0, 2, 0))
dev.off()
cat("✓ 15_correlation_axes.png\n")

# ============================================================================
# GRAPHIQUE 16: CERCLE DIM1-DIM3
# ============================================================================

png(paste0(output_dir, "16_cercle_dim1_dim3.png"), width = 800, height = 800, res = 100)
print(fviz_pca_var(res.acp, 
             axes = c(1, 3),
             col.var = "contrib",
             gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"),
             repel = TRUE,
             title = "Cercle des corrélations (Dim1-Dim3)") +
  coord_fixed(ratio = 1))
dev.off()
cat("✓ 16_cercle_dim1_dim3.png\n")

# ============================================================================
# SORTIE TEXTE: VALEURS PROPRES
# ============================================================================

cat("\n=== VALEURS PROPRES ===\n")
print(round(res.acp$eig, 3))

cat("\n=== COORDONNÉES DES VARIABLES (Dim 1-5) ===\n")
print(round(res.acp$var$coord[, 1:5], 3))

cat("\n=== CONTRIBUTIONS DES VARIABLES (%) ===\n")
print(round(res.acp$var$contrib[, 1:5], 2))

cat("\n=== COS² DES VARIABLES ===\n")
print(round(res.acp$var$cos2[, 1:5], 3))

cat("\n✅ Tous les graphiques ont été générés dans:", output_dir, "\n")
