/*******************************************************************************/
/*                                                                             */
/*                   Financial Ratios for Accounting Research                  */
/*                                                                             */
/*  Program      : 00-Master.sas                                               */
/*  Author       : Attila Balogh, School of Banking and Finance                */
/*                 UNSW Business School, UNSW Sydney                           */
/*  Date Created : Aug 2017                                                    */
/*  Last Modified: Aug 2017                                                    */
/*                                                                             */
/*  Description  : Master file with references to separate ratio calculators   */ 
/*                                                                             */
/*  Notes        : This code provides guidance on the appropriate calculation  */
/*                 of financial ratios for capital markets-based empirical     */
/*                 research in accounting and finance.	                       */
/*                 Practical examples are provided employing the widely-used   */
/*                 Compustat database accessed though Wharton Research         */
/*                 Data Services (WRDS).                                       */
/*                                                                             */
/*                 The calculation steps are described in Balogh "Financial    */
/*                 Ratios for Accounting Research" (Working paper, 2017)       */
/*                                                                             */
/*******************************************************************************/

/*	Importing the dataset from the WRDS Compustat database (requires access)   */

%include "01-Dataset_import.sas" ;

/*	Calculating Return on Net Operating Assets (RNOA)                          */

%include "02-RNOA.sas" ;

