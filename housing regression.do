 **Simple Granger
 import excel using housing.xlsx, firstrow
 reg LNGDP L1GDP L2GDP L1PRFI L2PRFI
 test L1PRFI=L2PRFI=0
 reg LNGDP L1GDP L2GDP L1GE L2GE
 test L1GE=L2GE=0
 reg LNGDP L1GDP L2GDP L1PCE L2PCE
 test L1PCE=L2PCE=0
 reg LNGDP L1GDP L2GDP L1PNFI L2PNFI
 test L1PNFI=L2PNFI=0

 



import excel using corr.xlsx, firstrow
**Stock and Bond Corr 
gen time=_n
tsset time

gen lngdp = ln(gdp)
gen gdp_growth = (lngdp - L.lngdp)*100
gen lninf = ln(cpi)
gen inf_growth = (lninf - L.lninf)*100


gen lnsp500 = ln(sp500)
gen stock_ret = (lnsp500 - L.lnsp500)*100
gen bond_ret = y3
egen mean_s = mean(stock_ret) 
egen mean_b = mean(bond_ret)
gen stock_reg = stock_ret - mean_s
gen bond_reg = bond_ret - mean_b

reg gdp_growth L.gdp_growth
predict gdp_shock, resid
reg inf_growth L.inf_growth
predict inf_shock, resid

save data, replace

rolling _b _se, window(40) saving(rolling_stock, replace): reg stock_reg gdp_shock inf_shock
use rolling_stock, clear
gen beta_sg = _b_gdp_shock
gen beta_sp = _b_inf_shock
save rolling_stock, replace


use data, clear
rolling _b _se, window(40) saving(rolling_bond, replace): reg bond_reg gdp_shock inf_shock
use rolling_bond, clear
gen beta_bg = _b_gdp_shock
gen beta_bp = _b_inf_shock
save rolling_bond, replace

use rolling_stock, clear
merge 1:1 _n using rolling_bond
save rolling_regressions, replace

use data, clear
rolling var_gdp=r(Var), window(40) saving(rolling_var_gdp, replace): summarize gdp_shock
rolling var_inf=r(Var), window(40) saving(rolling_var_inf, replace): summarize inf_shock
rolling cov_gdp_inf=r(cov_12), window(40) saving(rolling_cov_gdp_inf, replace): correlate gdp_shock inf_shock, cov

// Merge the statistics with the regression results
use rolling_regressions, clear
drop _merge
merge 1:1 _n using rolling_var_gdp
drop _merge
merge 1:1 _n using rolling_var_inf
drop _merge
merge 1:1 _n using rolling_cov_gdp_inf
save rolling_regressions, replace

gen cov_sb = (beta_sg * beta_bg * var_gdp) + (beta_sp * beta_bp * var_inf) + ((beta_sg * beta_bp + beta_sp * beta_bg) * cov_gdp_inf)
gen var_s = (beta_sg^2 * var_gdp) + (beta_sp^2 * var_inf) + 2 * beta_sg * beta_sp * cov_gdp_inf

gen var_b = (beta_bg^2 * var_gdp) + (beta_bp^2 * var_inf) + 2 * beta_bg * beta_bp * cov_gdp_inf

gen corr_sb = cov_sb / (sqrt(var_s * var_b))

list beta_sg beta_sp beta_bg beta_bp var_gdp var_inf cov_gdp_inf cov_sb corr_sb in 1/10
save final_rolling_regressions, replace

export excel using "final_corr.xlsx", firstrow(variables) sheet("Sheet1") replace

