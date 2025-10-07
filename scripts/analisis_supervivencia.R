
library(survival)
library(survminer)
set.seed(123)


mirnas_modelo_cox <- function(p_value, 
                              hazard_ratio_inferior, 
                              hazard_ratio_superior,
                              df_mirnas, 
                              df_completo){
  
  vector_mirnas <- vector()
  vector_pvalor <- vector()
  vector_hr <- vector()
  lista_mirnas <- rownames(df_mirnas)
  
  datos_supervivencia_mirnas <- df_completo[,c("time","vital_status",lista_mirnas)] %>%
    mutate(across(everything(), as.numeric))
  
  for(i in 1:length(lista_mirnas)){
    
    expr_mirnas <- datos_supervivencia_mirnas[,lista_mirnas[i]]
    modelo_cox <- coxph(Surv(time, vital_status) ~ log2(expr_mirnas + 1),
                        data = datos_supervivencia_mirnas)
    resumen_cox <- summary(modelo_cox)
    p_valor_cox <- resumen_cox$coefficients[,"Pr(>|z|)"]
    hr_cox <- resumen_cox$coefficients[,"exp(coef)"]
    
    if(p_valor_cox < p_value & 
       (hr_cox > hazard_ratio_superior | hr_cox < hazard_ratio_inferior)){
      vector_mirnas <- c(vector_mirnas, lista_mirnas[i])
      vector_pvalor <- c(vector_pvalor, p_valor_cox)
      vector_hr <- c(vector_hr, hr_cox)
    }
  }
  return(list(vector_mirnas, vector_pvalor, vector_hr, length(vector_mirnas)))
}


curva_kaplan_meier <- function(lista_mirnas, lista_hr, mirna_escogido, df_completo){
  
  datos_supervivencia_mirnas <- df_completo[,c("time","vital_status",lista_mirnas)] %>%
    mutate(across(everything(), as.numeric))
  
  if (length(lista_mirnas) == 1){
    expr_mirnas <- datos_supervivencia_mirnas[,lista_mirnas]
    datos_supervivencia_mirnas$group <-
      ifelse(expr_mirnas >= median(expr_mirnas),
             "Expresión alta", "Expresión baja")
  }else{
    expr_mirnas <- datos_supervivencia_mirnas[,lista_mirnas][mirna_escogido]
    datos_supervivencia_mirnas$group <-
      ifelse(expr_mirnas[,1] >= median(expr_mirnas[,1]),
             "Expresión alta", "Expresión baja")
  }
  
  curva <- survfit(Surv(time, vital_status) ~ group,
                   data = datos_supervivencia_mirnas, 
                   type = "kaplan-meier")
  
  plot <- ggsurvplot(fit = curva, data = datos_supervivencia_mirnas, 
             title = paste("Curvas de Kaplan-Meier para", 
                           mirna_escogido),
             xlab = "Tiempo (días)", ylab = "Prob. de supervivencia")
  
  pos <- which(unlist(lista_mirnas) == mirna_escogido)
  
  plot$plot <- plot$plot + 
                annotate("text", 
                         x = 0.6, 
                         y = 0.2, 
                         label = paste0("Hazard Ratio = ", 
                                        round(lista_hr[pos], 2)),
                         size = 5, hjust = 0)

  print(plot)
}


datos_modelo_tras_cox <- function(lista_mirnas, lista_pvalor, lista_hr){
  df <- data.frame(lista_pvalor, lista_hr, row.names = lista_mirnas)
  colnames(df)[1:2] <- c("p-valor", "hazard ratio")
  return(df)
}

