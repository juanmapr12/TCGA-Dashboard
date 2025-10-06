# Análisis de expresión diferencial:

saca_pareadas <- function(muestras_totales){
  
  # 1.
  id_paciente <- sapply(strsplit(muestras_totales, "-"), 
                        function(x) paste(x[1:3], collapse = "-"))
  
  # 2. 
  tipo_muestra <- sapply(strsplit(muestras_totales, "-"), 
                         function(x) x[4])
  
  # 3.
  df <- data.frame(
    paciente = id_paciente,
    tipo = tipo_muestra
  )
  
  # 4. 
  muestras_pareadas <- df %>%
    group_by(paciente) %>%
    filter(all(c("01", "11") %in% tipo)) %>%
    ungroup() %>%
    arrange(paciente) %>%
    mutate(union = paste(paciente, tipo, sep="-")) %>%
    pull(union)
  
  return(muestras_pareadas)
}


analisis_expr_dif <- function(muestras_escogidas, df_expresiones_mirnas, df_completo){
  
  grupo <- vector(mode="character")
  
  if (muestras_escogidas == "Totales"){
    muestras <- colnames(df_expresiones_mirnas)
  }else if (muestras_escogidas == "Pareadas"){
    muestras <- saca_pareadas(colnames(df_expresiones_mirnas))
  }
  
  for (i in 1:length(muestras)){
    tipo_muestra <- sapply(strsplit(muestras[i], "-"),
                           function(x) x[4])
    if (tipo_muestra == "01"){
      grupo <- c(grupo, "enfermo")
    }else{
      grupo <- c(grupo, "sano")
    }
  }
  
  grupo <- factor(grupo)
  grupo <- relevel(grupo, ref = "enfermo")
  design <- model.matrix(~ grupo)
  
  # Simplemente expresamos los CPM en log2 para poder aplicarles limma
  log_expr <- log2(df_expresiones_mirnas[,muestras] + 1)
  
  fit <- lmFit(log_expr, design)
  fit <- eBayes(fit)
  tabla <- topTable(fit, coef = 2, number = Inf)
  
  return(tabla)
}


volcano <- function(tabla_resultados, umbral_logFC, umbral_logFC_negativo, umbral_pvalor_ajustado){
  
  return(EnhancedVolcano(tabla_resultados,
                        title = "Volcano Plot para los parámetros seleccionados",
                        lab = rownames(tabla_resultados),
                        x = 'logFC',
                        y = 'adj.P.Val',
                        FCcutoff = umbral_logFC,
                        pCutoff = 10^(-(umbral_pvalor_ajustado))))
}


mirnas_que_cumplen_ambos_filtros <- function(resultado_analisis, 
                                             umbral_logFC, 
                                             umbral_logFC_negativo, 
                                             umbral_pvalor_ajustado){
  tt_filtrado <- subset(
    resultado_analisis,
    adj.P.Val < 10^(-(umbral_pvalor_ajustado)) & 
      (logFC > umbral_logFC |
      logFC < umbral_logFC_negativo)
  )
  return(tt_filtrado[,c("logFC", "adj.P.Val")])
}

