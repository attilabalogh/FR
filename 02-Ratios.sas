/*******************************************************************************/
/*                                                                             */
/*                   Financial Ratios for Accounting Research                  */
/*                                                                             */
/*  Program      : 02-Ratios.sas                                               */
/*  Author       : Attila Balogh, School of Banking and Finance                */
/*                 UNSW Business School, UNSW Sydney                           */
/*  Date Created : 17 Oct 2017                                                 */
/*  Last Modified: 27 Oct 2017                                                 */
/*                                                                             */
/*  Description  : Calculate Return on Net Operating Assets using Compustat    */ 
/*                 along with a host of other financial ratios                 */ 
/*                                                                             */
/*  Notes        : The program is based on the definitions used by Nissim and  */
/*                 Penman "Ratio Analysis and Equity Valuation: From Research  */
/*                 to Practice" (Review of Accounting Studies, 2001).          */
/*                                                                             */
/*                 Please reference the following paper when using this code   */
/*                 Balogh, A, Financial Ratios for Accounting Research         */
/*                 Available at SSRN: https://ssrn.com/abstract=3053402        */
/*                                                                             */
/*                 This program is to be used in conjunction with prerequisite */
/*                 programs listed in the 00-Master.sas file                   */
/*******************************************************************************/

/*  Setting key Compustat variable names                                       */
%let MainVars = gvkey fyear /*conm*/;

/*  Setting RNOA-specific Compustat variable names                             */
%let ROAVars = NI DVP MSA RECTA MII MIB XINT IDIT CEQ TSTKP DVPA DLC DLTT PSTK TSTKP DVPA CHE IVAO SALE EIEA NOPI SPI XIDO;

/*  Setting standard Compustat Filters                                         */
%let CSfilter = (
/*  Level of Consolidation Data - Consolidated                                 */
	(consol eq "C") and
/*  Data Format - Standardized */
/*  Exclude SUMM_STD (Domestic Annual Restated Data)                           */
	(datafmt eq "STD") and
/*  Population Source - Domestic (USA, Canada and ADRs)                        */
	(popsrc eq "D") and
	(not missing(fyear)) and
/*  Industry Format - Financial Services                                       */
/*  Some firms report in both formats and                                      */
/*  that can be responsible for duplicates                                     */
	(indfmt eq "INDL") and
/*  Assets total: missing */
	(at notin(0,.)) and
	(sale notin(0,.)) and
/*  Comparability Status - Company has undergone a fiscal year change.         */
/*  Some or all data may not be available                                      */
	(COMPST ne 'DB') );

/*  Either use a subset of the Compustat universe previously filtered to       */
/*  firm-year observations of interest A_FR_00, or the entire Compustat        */
/*  universe. The below code starts with the entire compm.funda dataset        */


data A_FR_01 ;
	set compm.funda;
/*	set A_FR_00;*/
	where &CSfilter.;
	keep &MainVars. &ROAVars.;
run;

/*	Optional: check that all relevant variables are kept                       */
/*

proc datasets memtype=data;
   contents data=A_FR_01;
run;

*/

/*	Change missing values to zero                                              */

/*	US Corporation Income Tax top rates                                        */
/*	https://www.irs.gov/pub/irs-soi/02corate.pdf                               */
/*  http://taxpolicycenter.org/taxfacts/Content/PDF/corporate_historical_bracket.pdf  */

%let g_AST = 0.02; /* Average state tax */

data A_FR_02 ;
	set A_FR_01;
	if fyear = 1950 then g_MTAX = (0.42 + &g_AST.);
	if fyear = 1951 then g_MTAX = (0.5075 + &g_AST.);
	if ((fyear >= 1952) and (fyear =< 1963)) then g_MTAX = (0.52 + &g_AST.);
	if fyear = 1964 then g_MTAX = (0.50 + &g_AST.);
	if ((fyear >= 1965) and (fyear =< 1967)) then g_MTAX = (0.48 + &g_AST.);
	if ((fyear >= 1968) and (fyear =< 1969)) then g_MTAX = (0.528 + &g_AST.);
	if fyear = 1970 then g_MTAX = (0.492 + &g_AST.);
	if ((fyear >= 1971) and (fyear =< 1978)) then g_MTAX = (0.48 + &g_AST.);
	if ((fyear >= 1979) and (fyear =< 1986)) then g_MTAX = (0.46 + &g_AST.);
	if fyear = 1987 then g_MTAX = (0.40 + &g_AST.);
	if ((fyear >= 1988) and (fyear =< 1992)) then g_MTAX = (0.34 + &g_AST.);
	if ((fyear >= 1993) and (fyear =< 2017)) then g_MTAX = (0.35 + &g_AST.);
		label g_MTAX = "Marginal Tax";
	if missing(NI) then NI = 0; 
	if missing(DVP) then DVP = 0; 
	if missing(MSA) then MSA = 0;  
	if missing(RECTA) then RECTA = 0;  
	if missing(MII) then MII = 0; 
	if missing(MIB) then MIB = 0;  
	if missing(XINT) then XINT = 0;  
	if missing(IDIT) then IDIT = 0;  
	if missing(CEQ) then CEQ = 0;  
	if missing(TSTKP) then TSTKP = 0;  
	if missing(DVPA) then DVPA = 0; 
	if missing(DLC) then DLC = 0; 
	if missing(DLTT) then DLTT = 0;  
	if missing(PSTK) then PSTK = 0;  
	if missing(TSTKP) then TSTKP = 0;  
	if missing(DVPA) then DVPA = 0; 
	if missing(CHE) then CHE = 0; 
	if missing(IVAO) then IVAO = 0;
	if missing(EIEA) then EIEA = 0;
	if missing(NOPI) then NOPI = 0;
	if missing(SPI) then SPI = 0;
	if missing(XIDO) then XIDO = 0; 
run;

/*  Creating lagMSA and lagRECTA variables                                     */

data A_FR_02_lag01 /*(RENAME=(fyear=fyear01 gvkey=gvkey01))*/;
	set A_FR_02;
	keep &MainVars. MSA RECTA;
run;

proc sort data = A_FR_02_lag01 nodupkey;
	by gvkey fyear;
run;

proc expand data=A_FR_02_lag01 out=A_FR_02_lag02 method=none;
	by gvkey;
	id fyear;
	convert MSA=g_lagMSA / transform=(lag);
	convert RECTA=g_lagRECTA / transform=(lag);
run;

data A_FR_02_lag02;
	set A_FR_02_lag02;
	if missing(g_lagMSA) then g_lagMSA = MSA;
	if missing(g_lagRECTA) then g_lagRECTA = RECTA;
	label g_lagMSA = "Marketable Securities Adjustment (t-1)";
	label g_lagRECTA = "Retained Earnings - Cumulative Translation Adjustment (t-1)";
	drop MSA RECTA;
run;

/*  Merging back lagSALE / lagMSA / lagRECTA                                   */

proc sql;
	create table A_FR_03 as
 		select a.*, b.g_lagMSA, b.g_lagRECTA
		from A_FR_02 a left join A_FR_02_lag02 b
		on a.gvkey = b.gvkey and a.fyear = b.fyear;
quit;

/*  Calculating financial ratios 1 of 2                                        */ 

data A_FR_04;
	set A_FR_03;

/*  Equation 2	*/
/*  Core Net Financial Expense (Core NFE) = after tax interest expense (#15 * (1 - marginal tax rate))
    plus preferred dividends (#19) and minus after tax interest income (#62 * (1 - marginal tax rate)).
    */
g_CNFE = (XINT * (1- g_MTAX )) + DVP - (IDIT * (1- g_MTAX));
	label g_CNFE = "Core Net Financial Expense";

/*	Equation 3	*/
/*	Unusual Financial Expense (UFE)=lag marketable securities adjustment (lag #238)
	minus marketable securities adjustment (#238).
    */
g_UFE = g_lagMSA - MSA;
	label g_UFE = "Unusual Financial Expense";

/*	Equation 4	*/
/*	Net Financial Expense (NFE) = Core Net Financial Expense (Core NFE) plus Unusual Financial Expense (UFE).
    */
g_NFE = g_CNFE + g_UFE;
	label g_NFE = "Net Financial Expense";

/*	Equation 5	*/
/*	Clean Surplus Adjustments to net income (CSA)=marketable securities adjustment (#238)
	minus lag marketable securities adjustment (lag #238) plus cumulative translation adjustment (#230)
	and minus lag cumulative translation adjustment (lag #230).                */
g_CSA = (MSA - g_lagMSA) + (RECTA - g_lagRECTA);
	label g_CSA = "Clean Surplus Adjustments to net income";

/*	Equation 6	*/
/*	Comprehensive Net Income (CNI) = net income (#172) minus preferred dividends (#19)
	and plus Clean Surplus Adjustment to net Income (CSA).
    */
g_CNI = NI - DVP + g_CSA;
	label g_CNI = "Comprehensive Net Income";

/*	Equation 7	*/
/*	Comprehensive Operating Income (OI) = Comprehensive Net Financial Expense (NFE)
	plus Comprehensive Net Income (CNI) and plus Minority Interest in Income (MII, #49).
   */
g_OI = g_NFE + g_CNI + MII;
	label g_OI = "Comprehensive Operating Income";

/*  Equation 9	*/
/*  Financial Obligations (FO) = debt in current liabilities (#34) plus long term debt (#9)
    plus preferred stock (#130) minus preferred treasury stock (#227)
    plus preferred dividends in arrears (#242).
    */
g_FO = DLC + DLTT + PSTK - TSTKP + DVPA;
	label g_FO = "Financial Obligations";

/*  Equation 10	*/
/*  Financial Assets (FA) = cash and short term investments (Compustat #1)
    plus investments and advances-other (Compustat #32).
    */
g_FA = CHE + IVAO;
	label g_FA = "Financial Assets";
/*  Equation 11	*/
/*  Net Financial Obligations (NFO) = Financial Obligations (FO) minus Financial Assets (FA).
    */
g_NFO = g_FO - g_FA;
	label g_NFO = "Net Financial Obligations";

/*  Equation 12	*/
/*  Common Equity (CSE) = common equity (#60) plus preferred treasury stock (#227)
    minus preferred dividends in arrears (#242).
    */
g_CSE = CEQ + TSTKP - DVPA;
	label g_CSE = "Common Equity";
/*	Equation 8	*/
/*  Net Operating Assets (NOA) = Net Financial Obligations (NFO)
    plus Common Equity (CSE) and plus Minority Interest (MI, #38)
    */
g_NOA = g_NFO + g_CSE + MIB;
	label g_NOA = "Net Operating Assets";

/*  Profit Margin  */
/*  Profit Margin (g_PM) = Comprehensive Operating Income (g_OI) / Sales/Turnover (Net) (SALE)
    */
if SALE ne 0 then g_PM = g_OI / SALE;
	label g_PM = "Profit Margin";

/*******************************************************************************/
/*  Core Sales Profit Margin calculations                                      */
/*******************************************************************************/

/*  Unusual Operating Income  */
g_UOI = (NOPI * (1- g_MTAX )) - EIEA + (SPI * (1- g_MTAX)) + XIDO + (RECTA - g_lagRECTA);
	label g_UOI = "Unusual Operating Income";

/*  Operating Income from Sales  */
g_OIS = g_OI - EIEA;
	label g_OIS = "Operating Income from Sales";

/*  Core Operating Income from Sales  */
g_COIS = g_OIS - g_UOI;
	label g_COIS = "Core Operating Income from Sales";

/*  Core Sales Profit Margin  */
if SALE ne 0 then g_CSPM = g_COIS / SALE;
	label g_CSPM = "Core Sales Profit Margin";

run;

/*******************************************************************************/
/*  Creating g_lagNOA, g_PM, g_lagCSE, and g_lagNFO variables                  */

data A_FR_04_lag01;
	set A_FR_04;
	keep &MainVars. g_NOA g_PM g_NFO g_CSE;
run;

proc sort data = A_FR_04_lag01 nodupkey;
	by gvkey fyear;
run;

proc expand data=A_FR_04_lag01 out=A_FR_04_lag02 method=none;
	by gvkey;
	id fyear;
	convert g_NOA=g_lagNOA / transform=(lag);
	convert g_CSE=g_lagCSE / transform=(lag);
	convert g_PM=g_lagPM / transform=(lag);
	convert g_NFO=g_lagNFO / transform=(lag);	
run;

data A_FR_04_lag02;
	set A_FR_04_lag02;
	drop g_NOA g_NFO g_CSE;
	label g_lagNOA = "Net Operating Assets (t-1)";
	label g_lagCSE = "Common Equity (t-1)";
	label g_lagPM = "Profit Margin (t-1)";
	label g_lagNFO = "Net Financial Obligations (t-1)";
run;

/*  Merging back g_lagNOA, g_lagCSE, and g_lagNFO                              */

proc sql;
	create table A_FR_05 as
 		select a.*, b.g_lagNOA, b.g_lagPM, b.g_lagCSE, b.g_lagNFO
		from A_FR_04 a left join A_FR_04_lag02 b
		on a.gvkey = b.gvkey and a.fyear = b.fyear;
quit;

/*  Calculating RNOA, NBC and additional ratios                                */
data C_FR_01;
	set A_FR_05;
/*  Average Net Financial Obligations  */
	if (g_lagNFO ne .) then g_AvgNFO = ((g_NFO + g_lagNFO) /2);
	label g_AvgNFO = "Average Net Financial Obligations";
	
/*  Net Borrowing Cost - average */
/*  Net Borrowing Cost (r_NBC) = Net Financial Expense (g_NFE) / Average Net Financial Obligations (g_AvgNFO)
	in the previous period).
    */
	if g_AvgNFO ne 0 then r_NBC = (g_NFE / g_AvgNFO); else r_NBC = . ;
	label r_NBC = "Net Borrowing Cost (avg)";

/*  Net Borrowing Cost - lagged */
/*  Net Borrowing Cost (NBC) = Net Financial Expense (g_NFE) / Average Net Financial Obligations (g_AvgNFO)
	in the previous period).
    */
	if g_lagNFO ne 0 then r_NBC_lag = (g_NFE / g_lagNFO); else r_NBC = . ;
	label r_NBC_lag = "Net Borrowing Cost (lag)";

/*  Average Common Equity  */
	if (g_lagCSE ne .) then g_AvgCSE = ((g_CSE + g_lagCSE) /2);
	label g_AvgCSE = "Average Common Equity";

/*  Leverage  */
/*  Leverage  (g_LEV) = Average Net Financial Obligations (g_AvgNFO) / Average Common Equity (g_AvgCSE)
    */
	if g_AvgCSE ne 0 then g_LEV = g_AvgNFO / g_AvgCSE;
	label g_LEV = "Leverage";

/*  Leverage  */
/*  Leverage  (g_LEV) = Net Financial Obligation (g_NFO) / Common Equity (g_CSE)
    */
	if g_lagCSE ne 0 then g_lagLEV = g_lagNFO / g_lagCSE;
	label g_lagLEV = "Leverage (t-1)";

/*  Average Net Operating Assets  */
	if (g_lagNOA ne 0) then g_AvgNOA = ((g_NOA + g_lagNOA) /2);
	label g_AvgNOA = "Average Net Operating Assets";

/*  Net Operating Asset Growth  */
	if (g_lagNOA ne 0) then g_GrNOA = ((g_NOA / g_lagNOA) -1);
	label g_GrNOA = "Net Operating Asset Growth";

/*  Profit Margin Growth (delta)  */
	if (g_lagPM ne 0) then g_dPM = (g_PM - g_lagPM);
	label g_dPM = "Profit Margin Growth";

/*  Asset Turnover  */
/*  Asset Turnover (g_ATO) = Sales/Turnover (Net) (SALE) / Average Net Operating Assets (g_NOA)
    */
	if (g_AvgNOA ne 0) then g_ATO = SALE / g_AvgNOA;
	label g_ATO = "Asset Turnover";

/*******************************************************************************/
/*  Equation 1 - with lagged NOA                                               */
/*  Return on Net Operating Assets (g_RNOA_lag) =
    Comprehensive Operating Income (g_OI)
    divided by lagged Net Operating Assets (g_lagNOA)                          */
if g_lagNOA ne 0 then g_RNOA_lag = g_OI / g_lagNOA;
	label g_RNOA_lag = "Return on Net Operating Assets (lag)";

/*******************************************************************************/
/*  Equation 1 - with average NOA                                              */
/*  Return on Net Operating Assets (g_RNOA_avg) =
    Comprehensive Operating Income (g_OI)
    divided by average Net Operating Assets (g_AvgNOA)                          */
if g_AvgNOA ne 0 then g_RNOA_avg = g_OI / g_AvgNOA;
	label g_RNOA_avg = "Return on Net Operating Assets (avg)";

/*  Spread  */
/*  Spread (g_SPRD) = Return on Net Operating Assets (g_RNOA_avg) - Net Borrowing Cost (r_NBC)
    */
g_SPRD = g_RNOA_avg - r_NBC;
	label g_SPRD = "Spread";

/*  Return on Common Equity  - average BS items */
/*  Net Borrowing Cost (r_NBC) = Net Financial Expense (g_NFE) / Net Financial Obligations (g_NFO)
	in the previous period).
    */
	if (g_AvgCSE ne 0) then r_ROCE = (  ((g_AvgNFO / g_AvgCSE) * g_RNOA_avg) - ((g_AvgNFO / g_AvgCSE) * r_NBC)  );
	label r_ROCE = "Return on Common Equity (avg)";

/*  Return on Common Equity - lagged BS items  */
/*  Net Borrowing Cost (r_NBC) = Net Financial Expense (g_NFE) / Net Financial Obligations (g_NFO)
	in the previous period).
    */
	if (g_lagCSE ne 0) then r_ROCE_lag = (  ((g_lagNOA / g_lagCSE) * g_RNOA_lag) - ((g_lagNFO / g_lagCSE) * r_NBC_lag)  );
	label r_ROCE_lag = "Return on Common Equity - (lag)";

	drop &ROAVars.;
run;

/*******************************************************************************/
/*                                                                             */
/*                         Additional Financial Ratios                         */
/*                                                                             */
/*******************************************************************************/

/*  Either use a subset of the Compustat universe previously filtered to       */
/*  firm-year observations of interest A_FR_00, or the entire Compustat        */
/*  universe. The below code starts with the entire compm.funda dataset        */

%let ADDLvars = DVC NI XAD XRD AM SALE EPSPX CSHO PRCC_F CEQ;

data B_FR_01 ;
	set compm.funda;
/*	set A_FR_00;*/
	where &CSfilter.;
	keep &MainVars. &ADDLvars.;
run;

data C_FR_02;
	set B_FR_01;

	/*  Earnings per Share  */
	g_EPS = EPSPX;
	label g_EPS = "Earnings Per Share";

/*  Dividend Payout Ratio  */
/*  Dividend Payout Ratio (g_DIVPAY) = Common Dividends (DVC) / Net Income (NI)
    */
	if NI ne 0 then g_DIVPAY = DVC / NI;
	label g_DIVPAY = "Dividend Payout Ratio";

/*  Innovation Intensity  */
/*  Innovation Intensity (g_INNOV) = Research and Development Expense (XRD) + Amortization of Intangibles (AM)
	divided by Sales/Turnover (Net) (SALE)
    */
	if SALE ne 0 then g_INNOV = (XRD + AM) / SALE;
	label g_INNOV = "Innovation Intensity";

/*  Advertising Intensity  */
/*  Advertising Intensity (g_ADVINT) = Research and Development Expense (XRD) + Amortization of Intangibles (AM)
	divided by Sales/Turnover (Net) (SALE)
    */
	if SALE ne 0 then g_ADVINT = (XAD / SALE);
	label g_ADVINT = "Advertising Intensity";

/*  Market Value of Equity  */
/*  Market Value of Equity (g_MVE) = Common Shares Outstanding (CSHO) times
	Price Close - Annual - Fiscal (PROC_F)
    */
	g_MVE = CSHO * PRCC_F;
	label g_MVE = "Market Value of Equity";

/*  Market-to-Book Ratio  */
/*  Market-to-Book Ratio (g_MTB) = Market Value of Equity (g_MVE)
	divided by Common/Ordinary Equity - Total (CEQ)
    */
	if CEQ ne 0 then g_MTB = (g_MVE / CEQ);
	label g_MTB = "Market-to-Book Ratio";

	drop &ADDLvars.;
run;

/*  Merging datasets                                   */

proc sql;
	create table D_FR_00 as
 		select a.*, b.*
		from C_FR_01 a left join C_FR_02 b
		on a.gvkey = b.gvkey and a.fyear = b.fyear;
quit;

/*  OPTIONAL: only if input dataset was a subset, not if compm.funda used      */

/*  Removing additional firm years obtained to lagged variables                */

/*

proc sql;
	create table B_FR_01 as
 		select a.gvkey as gvkeyIN, a.fyear as fyearIN, b.*
		from A_FR_00 a left join B_FR_00 b
		on a.gvkey = b.gvkey and a.fyear = b.fyear;
quit;

*/

/*  Saving dataset for download  */
/*
data FR.Balogh_Financial_ratios ;
	set D_FR_00;
run;
*/

/*  Cleanup                                                                    */

Proc datasets memtype=data nolist;
	delete A_FR_: B_FR_: ;
quit;

/* *************************************************************************** */
/* *************************  Attila Balogh, 2017  *************************** */
/* *************************************************************************** */
