/*******************************************************************************/
/*                                                                             */
/*                   Financial Ratios for Accounting Research                  */
/*                                                                             */
/*  Program      : 03-Firm_age.sas                                             */
/*  Author       : Attila Balogh, School of Banking and Finance                */
/*                 UNSW Business School, UNSW Sydney                           */
/*  Date Created : 17 Oct 2017                                                 */
/*  Last Modified: 17 Oct 2017                                                 */
/*                                                                             */
/*  Description  : Calculate firm age using Compustat and CRSP                 */ 
/*                                                                             */
/*  Notes        : This code provides guidance on the appropriate calculation  */
/*                 of financial ratios for capital markets-based empirical     */
/*                 research in accounting and finance.	                       */
/*                 Practical examples are provided employing the widely-used   */
/*                 Compustat database accessed though Wharton Research         */
/*                 Data Services (WRDS).                                       */
/*                                                                             */
/*                 Please reference the following paper when using this code   */
/*                 Balogh, A, Financial Ratios for Accounting Research         */
/*                 Available at SSRN: https://ssrn.com/abstract=3053402        */
/*                                                                             */
/*                 This program is to be used in conjunction with prerequisite */
/*                 programs listed in the 00-Master.sas file                   */
/*******************************************************************************/



/*  https://wrds-web.wharton.upenn.edu/wrds/ds/crsp/ccm_a/linktable/index.cfm?navId=120  */
/*  The WRDS-created linking dataset (ccmxpf_linktable) has been deprecated.   */
/*  Programmers should use the Link History dataset (crsp.ccmxpf_lnkhist)      */

/*  Uncomment this section is connecting to WRDS remotely                      */

/* Start

    %let wrds = wrds.wharton.upenn.edu 4016;
    options comamid=TCP remote=wrds;
    signon username=_prompt_ password=_prompt_;

    rsubmit;

    proc upload data=A_input_00;
    run;

    End                                                                        */

/*  Obtaining Total Assets for query firms                                     */
/*  NB the A_input_00 dataset was created in 01-Dataset_import.sas             */

%let CS_filter=consol='C' and datafmt='STD' and popsrc='D' and indfmt='INDL'; 
/*
proc sql;
	create table A_Age_00 as
 		select a.gvkey as gvkeyA, a.fyear as fyearA, b.gvkey, b.fyear, b.conm, b.datadate, b.at
		from A_input_00 a left join compm.funda (where=(&CS_filter)) b
		on a.gvkey = b.gvkey and a.fyear = b.fyear;
quit;
*/

data A_Age_00 (keep=gvkeyA fyearA fyear conm datadate at);
	set compm.funda;
	where fyear > 1985 and &CS_filter;
	fyearA = fyear;
	rename gvkey=gvkeyA;
run;

/*  Obtaining CRSP Permno for dataset linking                                 */

%let andlt = %str(and LINKTYPE in ('LC' 'LU' 'LX' 'LD' 'LS' 'LN'));
%let andld = and (LINKDT <= datadate or LINKDT = .B) and (datadate <= LINKENDDT or LINKENDDT = .E);

proc sql;
create table A_Age_01 as
 		select a.gvkeyA, a.fyear, a.conm, a.datadate, a.at, b.*
		from A_Age_00 a left join Crsp.Ccmxpf_lnkhist b
		on a.gvkeyA = b.gvkey &andld &andlt;
quit;

/*  Delete duplicates due to LINKPRIM C & N for some OBSs                      */
/*  http://www.crsp.com/products/documentation/link-history-data               */

data A_Age_01_01;
	set A_Age_01;
	if linkprim = 'P' then lpid = 4;
	if linkprim = 'J' then lpid = 3;
	if linkprim = 'C' then lpid = 2;
	if linkprim = 'N' then lpid = 1;
	if linkprim = '' then lpid = 0;
run;

proc sort data=A_Age_01_01;
	by gvkey fyear descending lpid;
run;

proc sort data=A_Age_01_01 nodupkey;
	by gvkey fyear;
run;

/*  Adding SIC and IPODATE from Compustat Company header info                  */
%let hdrvars  = %upcase(sic ipodate); 
proc sql;
    create table A_Age_02 as
        select a.*, b.gvkey as gvkeyB, b.sic, b.ipodate
        from A_Age_01_01 as a left join comp.company as b
        on a.gvkey = b.gvkey;
quit;

/*  Adding CRSP for listing dates                                              */
proc sql;
    create table A_Age_03 as
        select *
        from A_Age_02 as a left join crsp.dsfhdr (keep=PERMNO PERMCO BEGDAT ENDDAT HSICIG HSICMG) as b
        on a.LPERMNO = b.PERMNO and a.LPERMCO = b.PERMCO;
quit;

/* Housecleaning                                                               */
data A_Age_04 (drop= gvkeyA gvkeyB linkprim liid linktype lpermno lpermco linkdt linkenddt lpid);
	set A_Age_03;
run;

/*  Uncomment this section is connecting to WRDS remotely                     */

/* Start

proc download data=A_Age_04 out=A_Age_04;
run;

endrsubmit;
signoff;

    End                                                                       */

/*
 *   This code is used to create an Adjusted Age life-cycle proxy

Time required for firms to mature varies across industry
Need to adjust firm age for cross-sectional age differences across industries
Generate industry indicator dummies (1 or 0): InDumi
Sort firms by size within industry into quintiles: SizeDum (1 or 0 for the kth quintile)
Regress Age on InDumi and SizeDumi and use the percentile rank of the residual value as a proxy for lifecycle

*/


/*  Select which industry classification to use                                */
/*  Options are SIC, HSICMG, HSICIG                                            */
%let ind=HSICMG;

/*  Select groupings. Options are 5 for quintiles                              */
/*  100 for percentiles                                                        */
%let group=100;
%let rank=%eval(&group.-1);


data A_Age_05 (keep=gvkey conm fyear begdat age logAT &ind. LastYear);
	set A_Age_04;
	where not missing(begdat);
	if year(begdat) < fyear then LastYear = fyear; else LastYear = year(begdat);
	Age = 1+ (LastYear - year(begdat));
	if at notin(.) then logAT = log(1+at);
run;

/*  Create Size rankings (quintiles, percentiles, etc)                         */
/*  within each year depending on group variable above                         */

proc sort data=A_Age_05 out=A_Age_05;
	by fyear;
run;
proc rank data=A_Age_05 out=A_Age_06 groups=&group.;
   var logAT;
   by fyear;
   ranks sizeQ;
run;

/*  Create dummies for each group                                              */

data A_Age_07 (drop=begdat LastYear);
	set A_Age_06;

%macro indID();
		%do i=0 %to &rank. %by 1;
	if sizeQ = &i. then size&i. = 1; else size&i. = 0;
		%end;
%mend;%indID;

	drop sizeQ;
run;

/*  Create dummies for each industry                                           */

data A_Age_08;
	set A_Age_07;

%macro indID();
		%do i=1 %to 99 %by 1;
	if &ind. = &i. then ind&i. = 1; else ind&i. = 0;
		%end;
%mend;%indID;

run;

/*  Regress Age on size and industry dummies and obtain residuals              */

proc reg data=A_Age_08 noprint;
	model Age = size: ind: ;
	output out=A_Age_09 r=AgeRes ;
quit;

/* Get a visual feel for the data                                              */
/*

proc reg data=A_Age_08 ;
	model Age = size: ind: ;
quit;

proc univariate data=A_Age_09;
      var AgeRes ;
      histogram / normal;
run;

*/

/*  Create Adjusted Age proxy by ranking residuals                             */

proc rank data=A_Age_09 out=A_Age_10 groups=&group.;
   var AgeRes;
   ranks AdjAge;
run;

data A_Age_10 (drop=size: ind: HSICMG logAT AgeRes);
	retain gvkey fyear conm Age AdjAge;
	set A_Age_10;
	label AdjAge=;
	rename gvkey=gvkeyAge fyear=fyearAge;
run;

/*  Cleanup                                                                    */

Proc datasets memtype=data nolist;
	delete A_Age_04-A_Age_09 ;
quit;

/*  Use the resulting dataset to look up GVKEY-FYAR                            */
/*  combinations for firms of interest                                         */

/* *************************************************************************** */
/* *************************  Attila Balogh, 2017  *************************** */
/* *************************************************************************** */
