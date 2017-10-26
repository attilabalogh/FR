/*******************************************************************************/
/*                                                                             */
/*                   Financial Ratios for Accounting Research                  */
/*                                                                             */
/*  Program      : 01-Dataset_import.sas                                       */
/*  Author       : Attila Balogh, School of Banking and Finance                */
/*                 UNSW Business School, UNSW Sydney                           */
/*  Date Created : 17 Oct 2017                                                 */
/*  Last Modified: 17 Oct 2017                                                 */
/*                                                                             */
/*  Description  : Import a Compustat dataset from the WRDS system             */ 
/*                                                                             */
/*  Notes        : The program to calculate financial ratios relies on an      */
/*                 initial dataset named A_input_00 with GVKEY-FYEAR           */
/*                 combinations for the firms of interest. In the absence of   */
/*                 such dataset, the program creates a test dataset to         */
/*                 demonstrate its workings.                                   */
/*                                                                             */
/*                 Please reference the following paper when using this code   */
/*                 Balogh, A, Financial Ratios for Accounting Research         */
/*                 Available at SSRN: https://ssrn.com/abstract=3053402        */
/*                                                                             */
/*	               This program is to be used in conjunction with prerequisite */
/*	               programs listed in the 00-Master.sas file                   */
/*******************************************************************************/

/*	Sample dataset to test functionality in the absence of a live input file   */

data A_input_00;
	informat gvkey $6.;
	informat fyear 6.;
	format gvkey $6.;
	format fyear F6.;
	infile datalines;
	input gvkey fyear;
return;
datalines;
001690 2010
001690 2011
001690 2012
001690 2013
001690 2014
011974 1998
011974 1999
011974 2000
011974 2001
011974 2002
029028 2010
029028 2011
029028 2012
029028 2013
029028 2014
170617 2010
170617 2011
170617 2012
170617 2013
170617 2014
061143 1993
061143 1994
061143 1995
061143 1996
061143 1997
061143 1998
002136 2005
002136 2006
002136 2007
002136 2008
002136 2009
002136 2010
183920 2005
183920 2006
183920 2007
183920 2008
183920 2009
183920 2010
;
run;

/*  Dataset import starts here with a starting dataset named A_input_00        */

/*  Creating lagged FYEAR dataset 				 		*/
data A_input_01;
	set A_input_00;
	Lfyear = fyear - 1;
	drop fyear;
	rename Lfyear = fyear;
run;

/*  Merging FYEAR and lagged FYEAR datasets				                       */
data A_input_02;
	set A_input_00 A_input_01;
run;

/*  Removing duplicates for final input dataset                                */
proc sort data=A_input_02 nodupkey;
	by gvkey fyear;
run;

/*  Connecting to WRDS to upload query file and obtain                         */
/*  Compustat dataset for the GVKEY-FYEAR combinations                         */

/*  Use this code if you need to connect to WRDS remotely                      */
/*  It first uploads the Input file, matches financial data from comp.funda    */
/*  and finally downloads the dataset to the local SAS instance                */

/*

%let wrds = wrds.wharton.upenn.edu 4016;
options comamid=TCP remote=wrds;
signon username=_prompt_ password=_prompt_;

rsubmit;
proc upload data=A_input_02;
run;
endrsubmit;

*/

proc sql;
	create table A_FR_00 as
 		select a.gvkey as gvkeyA, a.fyear as fyearA, b.*
		from A_input_02 a left join compm.funda b
		on a.gvkey = b.gvkey and a.fyear = b.fyear;
quit;

/*  Use this code if you need to connect to WRDS remotely                      */

/*

rsubmit;
proc download data=A_FR_00 out=A_FR_00;
run;
endrsubmit;
signoff;

*/

/* *************************************************************************** */
/* *************************  Attila Balogh, 2017  *************************** */
/* *************************************************************************** */
