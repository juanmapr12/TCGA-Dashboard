# ---- Paquetes CRAN ----

cran_packages <- c(
  "shiny", "shinydashboard", "shinyWidgets", "shinyalert",
  "DT", "moments", "ggplot2", "dplyr", "tidyr",
  "tidymodels", "pheatmap", "discrim", "survival",
  "survminer", "ranger", "glmnet", "xgboost", "kernlab"
)

# Instalar los que faltan en CRAN
cran_missing <- cran_packages[!cran_packages %in% installed.packages()[,"Package"]]
if (length(cran_missing) > 0) {
  install.packages(cran_missing, dependencies = TRUE)
}

# ---- Paquetes Bioconductor ----

if (!requireNamespace("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager")
}

bioc_packages <- c(
  "GDCRNATools", "impute", "EnhancedVolcano",
  "limma", "multiMiR", "clusterProfiler",
  "org.Hs.eg.db", "enrichplot"
)

# Instalar los que faltan en Bioconductor
bioc_missing <- bioc_packages[!bioc_packages %in% installed.packages()[,"Package"]]
if (length(bioc_missing) > 0) {
  BiocManager::install(bioc_missing, ask = FALSE)
}

# ---- Verificación de carga ----

all_packages <- c(cran_packages, bioc_packages)

for (pkg in all_packages) {
  suppressPackageStartupMessages(library(pkg, character.only = TRUE))
  message(paste("✅ Paquete listo:", pkg))
}