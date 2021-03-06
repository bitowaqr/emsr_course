f_wrapper_determ <- function(
  
  #-- User adjustable inputs --#
  
  # age at baseline
  n_age_init = 25, 
  # maximum age of follow up
  n_age_max  = 110,
  # discount rate for costs and QALYS 
  d_r = 0.035,
  # number of simulations
 # n_sim   = 1000,
  # cost of treatment
  c_Trt   = 50      
  
){
  
  # need to specify environment of inner functions (to use outer function environment)
  # alternatively - define functions within the wrapper function.
  environment(f_gen_determ)         <- environment()
  environment(f_MM_sicksicker)   <- environment()
  
  #-- Nonadjustable inputs --#
  
  #  number of cycles
  n_t <- n_age_max - n_age_init
  # the 4 health states of the model:
  v_n <- c("H", "S1", "S2", "D") 
  # number of health states 
  n_states <- length(v_n) 
  
  #-- Create PSA Inputs --#
  
  df_determ <- f_gen_determ(c_Trt =  c_Trt)
  
  #--  Run One way sensitivity analysis  --#
  
  # Initialize matrix of results outcomes
  m_out <- matrix(NaN, 
                  nrow = nrow(df_determ), 
                  ncol = 5,
                  dimnames = list(1:nrow(df_determ),
                                  c("Cost_NoTrt", "Cost_Trt",
                                    "QALY_NoTrt", "QALY_Trt",
                                    "ICER")))
  
  # run model for each row of PSA inputs
  for(i in 1:nrow(df_determ)){
    
    # store results in row of results matrix
    m_out[i,] <- f_MM_sicksicker(df_determ[i, ])
    
  } # close model loop
  
  
  #-- Return results --#
  
  # convert matrix to dataframe (for plots)
  df_out <- as.data.frame(m_out) 
  
  # output the dataframe from the function  
  return(df_out) 
  
} # end of function

