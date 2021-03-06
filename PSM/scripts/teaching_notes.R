# -----------------------------------------------#
##### DISCLAIMER:
#####   DO NOT RUN
#####   THESE ARE JUST TEACHING NOTES
#####   CODE MAY BREAK
# -----------------------------------------------#

# psm
# author: paul schneider
# date/version: 15 feb 2021
# ---------------------------------


# Coding conventions --------

# 1 commenting

# Header 1 --------------------

# Header 2 ---------------

##### subheading

# comments above
1+1 # side comment


# 2 spacing
  # bad
  plot(x=xCoord,y=ataMat[,makeColName(metric,ptiles[1],"roiOpt")],ylim=ylim,xlab="dates",ylab=metric,main=(paste(metric,"sample",sep="")))
  # good
  plot(x    = xCoord,
       y    = dataMat[, makeColName(metric, ptiles[1], "roiOpt")],
       ylim = ylim,
       xlab = "dates",
       ylab = metric,
       main = (paste(metric, " for 3 samples ", sep=""))
  )



# 3 naming conventions
  myFunction <- function(){}
  snake_case <- c(12,3,4,5)
  c_drugA <- 123123
  u_pfs <- 0.9
  q_pfs <- 12
  df_os <- data.frame()
  mat_os <- matrix()
  
  # bad
  yhat <- 1
  theta <- 2
  mx <- 3
  gr.x <- 4


  
# 4. build your own code! 




# start PSM
##------------------------------------
# PSM

# load pkgs
library(survival)
library(flexsurv)
library(ggplot2)

# OS trial data
df_os <- read.csv("./data/trial_os.csv")
head(df_os)
surv_os <- Surv(time = df_os$eventtime, event =  df_os$status)
os_reg <- flexsurvreg(surv_os ~ trt, data = df_os, dist = "weibullph")
os_reg

# PFS
df_pfs <- read.csv("./data/trial_pfs.csv")
surv_pfs <- Surv(time = df_pfs$eventtime, event = df_pfs$status)
pfs_reg <- flexsurvreg(surv_pfs ~ trt, data = df_pfs,dist = "weibullph")
pfs_reg


# retrieve parameters
os_shape <- os_reg$res[1,1]
os_shape
os_scale_soc <- os_reg$res[2,1]
os_scale_soc
os_scale_supi <- os_scale_soc * exp(os_reg$res[3,1])
os_scale_supi

pfs_shape <- pfs_reg$res[1,1]
pfs_scale_soc <- pfs_reg$res[2,1]
pfs_scale_supi <- pfs_reg$res[2,1] * exp(pfs_reg$res[3,1])

# define time steps
times <- seq(from = 0 , to = 10, by = 1)

# predict curves
# OS
pred_os_soc <- 1 - os_reg$dfns$p(times, shape = os_shape, scale = os_scale_soc)
pred_os_supi <- 1- os_reg$dfns$p(times, shape = os_shape, scale = os_scale_supi) 

# PFS curves
pred_pfs_soc <- 1 - pfs_reg$dfns$p(times,shape=pfs_shape,scale = pfs_scale_soc)
pred_pfs_supi <- 1 - pfs_reg$dfns$p(times,shape=pfs_shape, scale = pfs_scale_supi)

# PPS
pred_pps_soc <- pred_os_soc - pred_pfs_soc
pred_pps_supi <- pred_os_supi - pred_pfs_supi

# dead 
pred_dead_soc <- 1 - pred_os_soc 
pred_dead_supi <- 1- pred_os_supi

# combine matrix
mat_surv <- cbind(
  pred_pfs_soc, pred_pps_soc, pred_dead_soc,
  pred_pfs_supi, pred_pps_supi, pred_dead_supi
)
# mat_surv


##########
#----------------------------------------------------#
# VISUALISE SURVIVAL CURVES
    kmPlotter <- function(event_times, group){
      # simplified KM plot df function
      # can only be used when there is NO CENSORING!
      uniq_g <- unique(group)
      res<- c()
      for(g in uniq_g){
        times <- event_times[group ==g]
        min_t <- min(times)
        max_t <- max(times)
        uniq_t <- unique(times)
        uniq_t <- uniq_t[order(uniq_t)]
        n <- length(times)
        S <- c(1)
        for(t in 2:length(uniq_t)){
          post_n <- sum(times > uniq_t[t])
          S <- c(S,post_n/ n  )
        }
        df <- data.frame(times = uniq_t, S, trt = g) 
        res <- rbind(res,df)
      }
      
      return(res)
    }
    
    km_plot_os <- kmPlotter(df_os$eventtime,df_os$trt)
    km_plot_pfs <- kmPlotter(df_pfs$eventtime,df_pfs$trt)
    
    # TOGETHER
    ggplot() +
      # OS KM observed
      geom_step(data = km_plot_os,aes(x=times, y= S, col = trt, linetype="OS"), alpha = 0.5) +
      # PFS KM observed
      geom_step(data = km_plot_pfs,aes(x=times, y= S, col = trt, linetype="PFS"), alpha = 0.5) +
      
      # Weibull est OS
      geom_line(aes(x=times,y=pred_os_soc,col = "SOC", linetype="OS" )) +
      geom_point(aes(x=times,y=pred_os_soc,col = "SOC" )) +
      
      geom_line(aes(x=times,y=pred_os_supi, col="Supimab",linetype="OS" )) +
      geom_point(aes(x=times,y=pred_os_supi, col="Supimab", )) +
      # Weibull est PFS
      geom_line(aes(x=times,y=pred_pfs_soc,col = "SOC", linetype="PFS" )) +
      geom_point(aes(x=times,y=pred_pfs_soc,col = "SOC")) +
      geom_line(aes(x=times,y=pred_pfs_supi, col="Supimab",linetype="PFS" )) +
      geom_point(aes(x=times,y=pred_pfs_supi, col="Supimab", )) +
      
      coord_cartesian(xlim=c(0,7)) +
      theme_minimal()
    
    # -------------       
        
        
      # AUC
      ## visualise AUC PPS + PFS SOC
      ggplot() +
        geom_ribbon(aes(x = times, ymin = 0,ymax = pred_pfs_soc, fill = "PFS")) +
        geom_ribbon(aes(x = times, ymin = pred_pfs_soc,ymax = pred_os_soc, fill = "PPS"), alpha = 0.7) +
        geom_line(aes(x = times, y = pred_pfs_soc)) +
        geom_line(aes(x = times, y = pred_os_soc)) +
        ## labels, axes, and legend
        ggtitle("PFS+PPS AUC - SOC ") +
        ylab("Cumulative survival") +
        scale_x_continuous(name = "Years", breaks = seq(0,10,2)) +
        scale_fill_manual(name = "State", 
                          labels = c("PFS AUC","PPS AUC"),
                          values = c("#00BFC4","cadetblue")) +
        theme_minimal() +
        theme(legend.position = "bottom")
      
      # AUC
        ## visualise AUC PPS + PFS Supimab
        ggplot() +
          geom_ribbon(aes(x = times, ymin = 0,ymax = pred_pfs_supi, fill = "PFS")) +
          geom_ribbon(aes(x = times, ymin = pred_pfs_supi,ymax = pred_os_supi, fill = "PPS"), alpha = 0.7) +
          geom_line(aes(x = times, y = pred_pfs_supi)) +
          geom_line(aes(x = times, y = pred_os_supi)) +
          ## labels, axes, and legend
          ggtitle("PFS+PPS AUC - Supimab ") +
          ylab("Cumulative survival") +
          scale_x_continuous(name = "Years", breaks = seq(0,10,2)) +
          scale_fill_manual(name = "State", 
                            labels = c("PFS AUC","PPS AUC"),
                            values = c("#00BFC4","cadetblue")) +
          theme_minimal() +
          theme(legend.position = "bottom")
        
###------------
# TRAPEZOID METHOD
#### -----------        


      vline_df <- data.frame(cbind(
        x = rep(times,2),
        y = c(cbind(0,pred_pfs_supi)),
        id = as.factor(rep(times,2))
      ))
      
      ggplot() +
        geom_ribbon(aes(x = times[1:2], ymin = 0,ymax = pred_pfs_supi[1:2], fill = "PFS")) +
        geom_line(aes(x = times, y = pred_pfs_supi)) +
        geom_line(data = vline_df, aes(x = x, y = y,group = id), linetype = "dashed") +
        geom_point(aes(
          x=c(times[1:2],times[1:2]),
          y=c(0,0,pred_pfs_supi[1:2]))) +
        ggrepel::geom_label_repel(aes(
          x=c(times[1:2],times[1:2]),
          y=c(0,0,pred_pfs_supi[1:2]),
          label = c("x1","x2","y1","y2")
        )) +
        geom_line(aes(
          x=c(0,times[1]),
          y=c(pred_pfs_supi[1],pred_pfs_supi[1])
        ), linetype = "dotted") +
        geom_line(aes(
          x=c(0,times[2]),
          y=c(pred_pfs_supi[2],pred_pfs_supi[2])
        ), linetype = "dotted") +
        theme_minimal() +
        xlim(c(0,4)) +
        geom_text(aes(x = 2.5,y = 0.65,label = "AUC = ( (y2+y1)/2)*(x2 - x1)"),size = 10) +
        theme(legend.position = "none") +
        ylab("S(t)") +
        xlab("Years")
##########

# ----- EXERCISE ------
times
pred_pfs_supi

((pred_pfs_supi[2] + pred_pfs_supi[1]) / 2 ) * (times[2] - times[1])
      
myAUC <- function(x, y){

}


#######################
# BREAK -------------------
########################


############################
# ------ SOLUTION ----------

myAUC <- function(x,y){
  auc <- rep(NA, times = length(y)-1)
  for (i in 2:(length(x))) {
    auc_i <- ( (y[i] + y[i - 1])/2 ) * (x[i] - x[i - 1])
    auc[i-1] <- auc_i
  }
  return(auc)
}

myAUC(x = times, y = pred_pfs_supi)




#########################################

# GOOGLE + copy/paste
#    "how to compute auc loop r"


# run time ------------------
myAUC_slow <- function(x,y){
  auc <- c()
  for (i in 2:(length(x))) {
    auc_i <- ( (y[i] + y[i - 1])/2 ) * (x[i] - x[i - 1])
    auc <- c(auc, auc_i)
  }
  return(auc)
}

y <- myAUC_slow(x = times, y = pred_pfs_supi)

###### ---------------------
# runtime test


test_time_points <- 1:10000
test_cum_surv <- runif(10000)
t1 <- Sys.time()
y <- myAUC_slow(x = test_time_points, y = test_cum_surv)
t2 <- Sys.time()
t2 - t1


test_time_points <- 1:50000
test_cum_surv <- runif(50000)
t1 <- Sys.time()
y <- myAUC(x = test_time_points, y = test_cum_surv)
t2 <- Sys.time()
t2 - t1


myAUC_fast <- function(x,y){
  auc <- ( (y[2:length(y)] +  y[1:(length(y)-1)]) / 2 ) * (x[2:length(x)] - x[1:(length(x)-1)])
  return(auc)
}

test_time_points <- 1:50000
test_cum_surv <- runif(50000)
t1 <- Sys.time()
y <- myAUC_fast(x = test_time_points, y = test_cum_surv)
t2 <- Sys.time()
t2 - t1


mat_auc <- apply(mat_surv,MARGIN = 2,FUN = myAUC, x = times)

mat_auc <- apply(mat_surv,MARGIN = 2,FUN = function(col){
  myAUC(x = times, y = col)
})


# -------------------------------------------------
# BREAK -------------------------
# -------------------------------------------------



mat_auc
rowSums(mat_auc) # time steps check
sum(mat_auc) # total auc check
colSums(mat_auc) # time spend in state

#----------------------------------------------------#
    ### visual inpsection of AUCs ------
    auc_df <- reshape2::melt(mat_auc)
    names(auc_df) <- c("time","state","auc")
    auc_df$trt <- ifelse(grepl("supi", auc_df$state),"supimab","soc")
    auc_df$state <- gsub("_soc","",auc_df$state)
    auc_df$state <- gsub("_supi","",auc_df$state)
    
    ggplot(auc_df, aes(fill=state, y=auc, x=time)) +
      geom_bar(position="stack", stat="identity") +
      facet_wrap(~trt) +
      theme_minimal()
#----------------------------------------------------#

    
    
        
# Define other input parameters
    # utilities
    u_pfs <- 0.90
    u_pps <-  0.65
    
    # costs soc
    c_soc <- 22000
    
    # costs supimab
    c_drug_supi <- 30000
    c_admin_supi <- 2000
    c_supi <- c_drug_supi + c_admin_supi
    
    # costs supportive care for post-progression
    c_support <- 5000
    
    # discount rate
    disc_rate = 0.035
    
    
# multiply the auc values with costs and qalys
c_pfs_supi <- mat_auc[, "pred_pfs_supi"] * c_supi
c_pps_supi <- mat_auc[,"pred_pps_supi"] * c_support
c_pfs_soc <- mat_auc[,"pred_pfs_soc"] * c_soc
c_pps_soc <- mat_auc[,"pred_pps_soc"] * c_support

q_pfs_supi <- mat_auc[,"pred_pfs_supi"] * u_pfs
q_pps_supi <- mat_auc[,"pred_pps_supi"] * u_pps
q_pfs_soc <- mat_auc[,"pred_pfs_soc"] * u_pfs
q_pps_soc <- mat_auc[,"pred_pps_soc"] * u_pps

# combines costs and qalys into matrices
c_mat <- cbind(c_pfs_supi, c_pps_supi, c_pfs_soc, c_pps_soc)

q_mat <- cbind(q_pfs_supi, q_pps_supi, q_pfs_soc, q_pps_soc)


# Define discount function and apply it to costs and qalys

# ---------------------------
# EXERCISE  2 - DISCOUNT FUNCTION
# discounting --------------
# cost /(1 + rate) ^ time
# e.g. cost /(1.035) ^ 2


# ---------------------------

# Define discount function and apply it to costs and qalys
myDiscounter <- function(x, time, rate = 0.035){
  res <- x /(1 + rate) ^ time 
  return(res)
}

c_mat_disc <- apply(c_mat, 2, myDiscounter, time = times[-1])
# c_mat_disc
q_mat_disc <- apply(q_mat,2,myDiscounter,time = times[-1])
# q_mat_disc


# summing up costs and qalys
total_costs_supi <- sum(c_mat_disc[,c("c_pfs_supi","c_pps_supi")])
# total_costs_supi

total_costs_soc <- sum(c_mat_disc[,c("c_pfs_soc","c_pps_soc")])
# total_costs_soc

# qalys supimab
total_qalys_supi <-sum(q_mat_disc[,c("q_pfs_supi","q_pps_supi")])
# total_qalys_supi

# qalys soc
total_qalys_soc <- sum(q_mat_disc[,c("q_pfs_soc","q_pps_soc")])
# total_qalys_soc

# ICER
mean( (total_costs_supi - total_costs_soc) / (total_qalys_supi - total_qalys_soc) )

# INB at 20k
inb_20 <-  (total_qalys_supi - total_qalys_soc) * 20000 - (total_costs_supi - total_costs_soc)
inb_20

# INB at 30k
inb_30 <-  (total_qalys_supi - total_qalys_soc) * 30000 - (total_costs_supi - total_costs_soc)
inb_30

wtp_steps <- seq(0, 50000, by = 1000)
inb_x <-  (total_qalys_supi - total_qalys_soc) * wtp_steps - (total_costs_supi - total_costs_soc)
cbind(wtp_steps, inb_x)


##### REPEAT ANALYSIS WITH HOURS


