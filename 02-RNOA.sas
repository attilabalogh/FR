/*******************************************************************************/
/*                                                                             */
/*                   Financial Ratios for Accounting Research                  */
/*                                                                             */
/*  Program      : 02-RNOA.sas                                                 */
/*  Author       : Attila Balogh, School of Banking and Finance                */
/*                 UNSW Business School, UNSW Sydney                           */
/*  Date Created : Aug 2017                                                    */
/*  Last Modified: Aug 2017                                                    */
/*                                                                             */
/*  Description  : Calculate Return on Net Operating Assets using Compustat    */ 
/*                                                                             */
/*  Notes        : The program is based on the definitions used by Nissim and  */
/*                 Penman "Ratio Analysis and Equity Valuation: From Research  */
/*                 to Practice" (Review of Accounting Studies, 2001).          */
/*                                                                             */
/*                 The calculation steps are described in Balogh "Financial    */
/*                 Ratios for Accounting Research" (Working paper, 2017)       */
/*                                                                             */
/*	               This program is to be used in conjunction with prerequisite */
/*	               programs listed in the 00-Master.sas file                   */
/*******************************************************************************/

/*	Setting key Compustat variable names			*/
%let MainVars = gvkey fyear conm;

/*	Setting RNOA-specific Compustat variable names	*/
%let ROAVars = NI DVP MSA RECTA MII MIB XINT IDIT CEQ TSTKP DVPA DLC DLTT PSTK TSTKP DVPA CHE IVAO;

/*	Setting standard Compustat Filters 				*/
%let CSfilter = (
/*	Level of Consolidation Data - Consolidated */
	(consol eq "C") and
/*	Data Format - Standardized */
	(datafmt eq "STD") and
/*	Population Source - Domestic (USA, Canada and ADRs) */
	(popsrc eq "D") and
	(not missing(fyear)) and
/* Industry Format - Financial Services   */
/* Some firms report in both formats and  */
/* that can be responsible for duplicates */
	(indfmt eq "INDL") and
/*	Assets total: missing */
	(at notin(0,.)) and
	(sale notin(0,.)) and
/*	Comparability Status - Company has undergone a fiscal year change. Some or all data may not be available */
	(COMPST ne 'DB') );

data A_FR_01 ;
	set A_FR_00;
	where &CSfilter.;
	keep &MainVars. &ROAVars.;
run;

/*	Optional: check all relevant variables are kept	*/
/*
proc datasets memtype=data;
   contents data=A_FR_01;
run;
*/
/*	Change missing values to zero */

/*	US Corporation Income Tax top rates				*/
/*	https://www.irs.gov/pub/irs-soi/02corate.pdf	*/

%let g_AST = 0.02; /* Average state tax */

data A_FR_02 ;
	set A_FR_01;
	if fyear > 1950 then g_MTAX = (0.42 + &g_AST.) ;
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
run;

/* Creating lagMSA and lagRECTA variables */

data A_FR_02_lag01 /*(RENAME=(fyear=fyear01 gvkey=gvkey01))*/;
	set A_FR_02;
	keep gvkey conm fyear MSA RECTA;
run;

proc sort data = A_FR_02_lag01;
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
	drop MSA RECTA conm;
	label g_lagMSA= g_lagRECTA=;
run;

/* Merging back lagSALE / lagMSA / lagRECTA */

proc sql;
	create table A_FR_03 as
 		select a.*, b.g_lagMSA, b.g_lagRECTA
		from A_FR_02 a left join A_FR_02_lag02 b
		on a.gvkey = b.gvkey and a.fyear = b.fyear;
quit;


/* Calculating financial ratios 1 of 2 */ 

data A_FR_04;
	set A_FR_03;

/*	Equation 2	*/
/*	Core Net Financial Expense (Core NFE) = after tax interest expense (#15 × (1 - marginal tax rate))
	plus preferred dividends (#19) and minus after tax interest income (#62 × (1 - marginal tax rate)).			*/
g_CNFE = (XINT * (1- g_MTAX )) + DVP - (IDIT * (1- g_MTAX));

/*	Equation 3	*/
/*	Unusual Financial Expense (UFE)=lag marketable securities adjustment (lag #238)
	minus marketable securities adjustment (#238).																*/
g_UFE = g_lagMSA - MSA;

/*	Equation 4	*/
/*	Net Financial Expense (NFE) = Core Net Financial Expense (Core NFE) plus Unusual Financial Expense (UFE).	*/
g_NFE = g_CNFE + g_UFE;

/*	Equation 5	*/
/*	Clean Surplus Adjustments to net income (CSA)=marketable securities adjustment (#238)
	minus lag marketable securities adjustment (lag #238) plus cumulative translation adjustment (#230)
	and minus lag cumulative translation adjustment (lag #230).													*/
g_CSA = (MSA - g_lagMSA) + (RECTA - g_lagRECTA);

/*	Equation 6	*/
/*	Comprehensive Net Income (CNI) = net income (#172) minus preferred dividends (#19)
	and plus Clean Surplus Adjustment to net Income (CSA).														*/
g_CNI = NI - DVP + g_CSA;

/*	Equation 7	*/
/*	Comprehensive Operating Income (OI) = Comprehensive Net Financial Expense (NFE)
	plus Comprehensive Net Income (CNI) and plus Minority Interest in Income (MII, #49).						*/
g_OI = g_NFE + g_CNI + MII;

/*	Equation 9	*/
/*	Financial Obligations (FO) = debt in current liabilities (#34) plus long term debt (#9)
	plus preferred stock (#130) minus preferred treasury stock (#227)
	plus preferred dividends in arrears (#242).																	*/
g_FO = DLC + DLTT + PSTK - TSTKP + DVPA;

/*	Equation 10	*/
/*	Financial Assets (FA) = cash and short term investments (Compustat #1)
	plus investments and advances-other (Compustat #32).														*/
g_FA = CHE + IVAO;

/*	Equation 11	*/
/*	Net Financial Obligations (NFO) = Financial Obligations (FO) minus Financial Assets (FA). */
g_NFO = g_FO - g_FA;

/*	Equation 12	*/
/*	Common Equity (CSE) = common equity (#60) plus preferred treasury stock (#227)
	minus preferred dividends in arrears (#242). */
g_CSE = CEQ + TSTKP - DVPA;

/*	Equation 8	*/
/*	Net Operating Assets (NOA) = Net Financial Obligations (NFO)
	plus Common Equity (CSE) and plus Minority Interest (MI, #38)												*/
g_NOA = g_NFO + g_CSE + MIB;

run;

/* Creating g_lagNOA variable */

data A_FR_04_lag01;
	set A_FR_04;
	keep gvkey conm fyear g_NOA;
run;

proc sort data = A_FR_04_lag01;
	by gvkey fyear;
run;

proc expand data=A_FR_04_lag01 out=A_FR_04_lag02 method=none;
	by gvkey;
	id fyear;
	convert g_NOA=g_lagNOA / transform=(lag);
run;

data A_FR_04_lag02;
	set A_FR_04_lag02;
	drop g_NOA conm;
run;

/* Merging back g_lagNOA */

proc sql;
	create table A_FR_05 as
 		select a.*, b.g_lagNOA
		from A_FR_04 a left join A_FR_04_lag02 b
		on a.gvkey = b.gvkey and a.fyear = b.fyear;
quit;

/*	Calculating RNOA	*/
data A_FR_06;
	set A_FR_05;

/*	Equation 1	*/
/*	Return on Net Operating Assets (g_RNOA) = Comprehensive Operating Income (g_OI)
	divided by lagged Net Operating Assets (g_lagNOA)												*/
g_RNOA = g_OI / g_lagNOA;
	drop &ROAVars.;
run;

/*	Removing additional firm years obtained to lagged variables	*/

proc sql;
	create table A_FR_07 as
 		select a.gvkey as gvkeyIN, a.fyear as fyearIN, b.*
		from A_input_02 a left join A_FR_06 b
		on a.gvkey = b.gvkey and a.fyear = b.fyear;
quit;
