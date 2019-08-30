/******************************************************************************************************************
Description: Establish views as input to Having a Baby in South Auckland

Input: IDI Clean

Output: A collection of views in IDI Sandpit
 
Author: Simon Anastasiadis, Michael Hackney, Athira Nair
Reviewer: Akilesh Chokkanathapuram
 
Dependencies:
 
Notes:
1) Currently locked to 2018-10-20 refersh
2) Required columns: snz_uid, start_date, end_date, description, value, source
3) Project prefix = "jt_"

Issues:
 
History (reverse order):
2018-04-26 SA recommneded changes from review
2018-04-23 AK review
2018-12-03 SA v0
******************************************************************************************************************/

/* Establish database for writing views */
USE IDI_UserCode
GO




/* TEMPLATE - CREATE A COPY - DON'T OVERWRITE 
EVENT: 
AUTHOR: 
DATE: 
Intended use: 

-- description goes here

REVIEWED 
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_VIEW_NAME]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_VIEW_NAME];
GO

/*CREATE VIEW [DL-MAA2016-15].jt_VIEW_NAME AS
SELECT snz_uid
	,[start_date]
	,[end_date]
	,[description]
	,[value]
	,[source]
FROM


GO
*/



/*
EVENT: First arrival from overseas
AUTHOR: Michael Hackney
DATE: 3/12/18
Intended use: Identification of recent migrants

Obtains first arrival date from Overseas Spell Table
start_date = end_date: as the end of the overseas spell (i.e. first arrival date)
description: is the stringe 'Recent migrant'
value: is the string 'y' in the original table when the individual is a migrant

REVIEWED: 
2018-12-05 Simon - set value as numeric
2019-04-09 AK
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_recent_migrant]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_recent_migrant];
GO

CREATE VIEW [DL-MAA2016-15].jt_recent_migrant AS

SELECT snz_uid
	,pos_ceased_date as "start_date"
	,pos_ceased_date as end_date
	,'migrant first arrival' as [description]
	,1 as value
	,'overseas spells' AS [source]
FROM [IDI_Clean_20181020].[data].[person_overseas_spell]
WHERE pos_first_arrival_ind = 'y';
GO

/* 
EVENT: Has ethnicity
AUTHOR: Michael Hackney
DATE: 3/12/18
Intended use: Identification of ethnicity

Ethnicity drawn from personal details.
Ethnicity is assumed to be universal, hence applies to all
time periods.

REVIEWED: 
2018-12-05 Simon
2019-04-09 AK
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_ETHNICITY]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_ETHNICITY];
GO

CREATE VIEW [DL-MAA2016-15].jt_ETHNICITY AS

-- European
SELECT personal_detail.snz_uid
		,'1900-01-01' AS "start_date"
		,'2100-01-01' AS end_date
		,'Ethnicity = EUROPEAN' AS "description"
		,1 as value
		,'personal details' AS [source]
FROM [IDI_Clean_20181020].[data].[personal_detail]
WHERE (snz_ethnicity_grp1_nbr = 1)

UNION ALL

-- Maori
SELECT personal_detail.snz_uid
		,'1900-01-01' AS "start_date"
		,'2100-01-01' AS end_date
		,'Ethnicity = MAORI' AS "description"
		,1 as value
		,'personal details' AS [source]
FROM [IDI_Clean_20181020].[data].[personal_detail]
WHERE snz_ethnicity_grp2_nbr = 1

UNION ALL

-- Pacific Peoples
SELECT personal_detail.snz_uid
		,'1900-01-01' AS "start_date"
		,'2100-01-01' AS end_date
		,'Ethnicity = PACIFIC' AS "description"
		,1 as value
		,'personal details' AS [source]
FROM [IDI_Clean_20181020].[data].[personal_detail]
WHERE (snz_ethnicity_grp3_nbr = 1)

UNION ALL

-- Asian
SELECT personal_detail.snz_uid
		,'1900-01-01' AS "start_date"
		,'2100-01-01' AS end_date
		,'Ethnicity = ASIAN' AS "description"
		,1 as value
		,'personal details' AS [source]
FROM [IDI_Clean_20181020].[data].[personal_detail]
WHERE (snz_ethnicity_grp4_nbr = 1)

UNION ALL

-- MIDDLE EASTERN/LATIN AMERICAN/AFRICAN
SELECT personal_detail.snz_uid
		,'1900-01-01' AS "start_date"
		,'2100-01-01' AS end_date
		,'Ethnicity = MELAA' AS "description"
		,1 as value
		,'personal details' AS [source]
FROM [IDI_Clean_20181020].[data].[personal_detail]
WHERE (snz_ethnicity_grp5_nbr = 1)

UNION ALL

-- OTHER ETHNICITY
SELECT personal_detail.snz_uid
		,'1900-01-01' AS "start_date"
		,'2100-01-01' AS end_date
		,'Ethnicity = OTHER' AS "description"
		,1 as value
		,'personal details' AS [source]
FROM [IDI_Clean_20181020].[data].[personal_detail]
WHERE (snz_ethnicity_grp6_nbr = 1);
GO

/*
EVENT: Marriage or Civil union
AUTHOR: Michael Hackney
DATE: 4/12/18
Intended use: To determine whether parents are married or solemenised

Drawn from marriage and civil union tables.
One record for each partner, with the other partner recorded as the value.


REVIEWED: 2018-12-05 Simon
- require start date is not null
- if end date is missing set far future
- require no one marries themselves
- civil unions drawn from civil union table
2019-04-23 AK
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_PARENTS_MARRIED]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_PARENTS_MARRIED];
GO

CREATE VIEW [DL-MAA2016-15].jt_PARENTS_MARRIED AS

/** snz_uid as Partner 1, marriage**/
SELECT [partnr1_snz_uid] as snz_uid
	,[dia_mar_marriage_date] as [start_date]
	,COALESCE([dia_mar_disolv_order_date], '9999-01-01') as end_date
	,'Married to' as [description]
	,[partnr2_snz_uid] as value
	,'dia marriages' AS [source]
FROM [IDI_Clean_20181020].[dia_clean].[marriages]
WHERE [dia_mar_marriage_date] IS NOT NULL
AND [partnr1_snz_uid] <> [partnr2_snz_uid]

UNION ALL

/** snz_uid as Partner 2, marriage**/
SELECT [partnr2_snz_uid] as snz_uid
	,[dia_mar_marriage_date] as [start_date]
	,COALESCE([dia_mar_disolv_order_date], '9999-01-01') as end_date
	,'Married to' as [description]
	,[partnr1_snz_uid] as value
	,'dia marriages' AS [source]
FROM [IDI_Clean_20181020].[dia_clean].[marriages]
WHERE [dia_mar_marriage_date] IS NOT NULL
AND [partnr1_snz_uid] <> [partnr2_snz_uid]

UNION ALL

/** snz_uid as Partner 1, civil union**/
SELECT [partnr1_snz_uid] as snz_uid
	,[dia_civ_civil_union_date] as [start_date]
	,COALESCE([dia_civ_disolv_order_date], '9999-01-01') as end_date
	,'In a civil union with' as [description]
	,[partnr2_snz_uid] as value
	,'dia civil unions' AS [source]
FROM [IDI_Clean_20181020].[dia_clean].[civil_unions]
WHERE [dia_civ_civil_union_date] IS NOT NULL
AND [partnr1_snz_uid] <> [partnr2_snz_uid]

UNION ALL

/** snz_uid as Partner 1, civil union**/
SELECT [partnr2_snz_uid] as snz_uid
	,[dia_civ_civil_union_date] as [start_date]
	,COALESCE([dia_civ_disolv_order_date], '9999-01-01') as end_date
	,'In a civil union with' as [description]
	,[partnr1_snz_uid] as value
	,'dia civil unions' AS [source]
FROM [IDI_Clean_20181020].[dia_clean].[civil_unions]
WHERE [dia_civ_civil_union_date] IS NOT NULL
AND [partnr1_snz_uid] <> [partnr2_snz_uid];
GO

/* 
EVENT: Time enrolled in education
AUTHOR: Michael Hackney
DATE: 4/12/18
Intended use: Identify periods of education on timeline, and
to count days/time in education.

Gives period of enrolment in secondary/tertiary education,
or industry training programs, or targeted training programs.
ISCED = international code for level of study.
NZSCED = NZ code for subject of study.

REVIEWED: 2018-12-05 Simon
- industry training must have an end date
- substring used to trim long descriptions
2019-04-09 AK
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_EDUCATION_PERIOD]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_EDUCATION_PERIOD];
GO

CREATE VIEW [DL-MAA2016-15].jt_EDUCATION_PERIOD AS
/*Enrolment in secondary or tertiary education*/
SELECT snz_uid
	,[moe_enr_prog_start_date] as [start_date]
	,[moe_enr_prog_end_date] as [end_date]
	,CASE WHEN [moe_enr_isced_level_code] LIKE '3_' THEN 'Upper secondary'
		WHEN [moe_enr_isced_level_code] LIKE '4_' THEN 'Post-secondary, non-tertiary'
		WHEN [moe_enr_isced_level_code] LIKE '5_' THEN '1st stage tertiary'
		WHEN [moe_enr_isced_level_code] = '6' THEN '2nd stage tertiary'
		ELSE 'Enrollment = Unknown'
		END AS [description]
	,1 as value
	,'moe enroll' AS [source]
FROM [IDI_Clean_20181020].[moe_clean].[enrolment]

UNION ALL

/*Enrolment in targeted training*/
SELECT snz_uid
	,[moe_ttr_placement_start_date] as [start_date]
	,[moe_ttr_placement_end_date] as [end_date]
	,'targeted training enroll' AS [description]
	,1 as value
	,'moe targeted training' AS [source]
FROM [IDI_Clean_20181020].[moe_clean].[targeted_training]

UNION ALL

/*Enrolment in industry training*/
SELECT [snz_uid]
	,[moe_itl_start_date] as [start_date]
	,[moe_itl_end_date] as end_date
	,CONCAT('indust train = ',SUBSTRING([moe_itl_nzsced_narrow_text], 1, 20)) as [description]
	,1 as value
	,'moe industry training' AS [source]
FROM [IDI_Clean_20181020].[moe_clean].[tec_it_learner]
WHERE [moe_itl_end_date] IS NOT NULL;
GO

/*
EVENT: T2 Benefit receipt by type
AUTHOR: Michael Hackney	
DATE: 4/12/18
Intended use: Identify periods of Tier 2 benefit receipt,
sum value of tier 2 benefit received, to identify the types of T2 benefits.

Periods of Tier 2 benefit receipt with daily amount received.

The IDI metadata database contains multiple tables that translate benefit type codes
into benefit names/descriptions. The differences between these tables are not well
explained.
Not every code appears in every table, hence for some applications we need to combine
multiple metadata tables.

REVIEWED: 2018-12-06 Simon
- archived manual list, replaced with join to metadata
- value change to total for period
2019-04-23 AK
- Code Index for codes 604, 605, 667 not available
- Joining two tables, table meta data not available
2019-04-26 SA
- explanation added above
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_T2_BENEFIT_RECEIPT]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_T2_BENEFIT_RECEIPT];
GO

CREATE VIEW [DL-MAA2016-15].jt_T2_BENEFIT_RECEIPT AS

SELECT snz_uid
	,msd_ste_start_date as [start_date]
	,[msd_ste_end_date] as end_date
	,[classification] AS [description]
	,[msd_ste_daily_gross_amt] * (1 + DATEDIFF(DAY, msd_ste_start_date, [msd_ste_end_date])) AS value
	,'msd t2 benefits' AS [source]
FROM [IDI_Clean_20181020].[msd_clean].[msd_second_tier_expenditure] t2
INNER JOIN (
	-- Code classifications
	SELECT [Code], [classification]
	FROM [IDI_Metadata].[clean_read_CLASSIFICATIONS].[msd_benefit_type_code]
	UNION ALL
	SELECT [Code], [classification]
	FROM [IDI_Metadata].[clean_read_CLASSIFICATIONS].[msd_benefit_type_code_4] -- add three codes that do not appear in the first metadata table
	WHERE Code IN (604, 605, 667)
) codes
ON t2.[msd_ste_supp_serv_code] = codes.Code
WHERE [msd_ste_supp_serv_code] IS NOT NULL;
GO

/*
EVENT: ACC accident
AUTHOR: Michael Hackney
DATE: 4/12/18
Intended use: Identification of ACC accident events

Identification of the date of an ACC claim. Additional details
(such as location of claim) not used due to unknown quality.

REVIEWED: 2018-12-06 Simon
- added substring to shorted long diagnoses
2019-04-23 AK
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_ACC_ACCIDENT]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_ACC_ACCIDENT];
GO

CREATE VIEW [DL-MAA2016-15].jt_ACC_ACCIDENT AS
SELECT snz_uid
	,claims.acc_cla_accident_date as "start_date"
	,claims.acc_cla_accident_date as end_date
	,'ACC claim' AS [description]
	,1 as value
	,'acc claim' AS [source]
FROM [IDI_Clean_20181020].[acc_clean].[claims];
GO

/*
EVENT: Mother's age at birth
AUTHOR: ATHIRA NAIR
DATE: 3/12/2018
Intended use: Mother's age at first birth, identification of first birth,
count of previous births

MOTHER
Maternity data includes mother's age at the time of birth.

REVIEWED 2018-12-06 Simon
- removed minimum as this will happen at intersection
- removed still births
2019-04-23 AK
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_MOTHER_AGE]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_MOTHER_AGE];
GO

CREATE VIEW [DL-MAA2016-15].jt_MOTHER_AGE AS
SELECT snz_uid
	   ,DATEFROMPARTS([moh_matm_delivery_year_nbr], [moh_matm_delivery_month_nbr], 15) as "start_date"
	   ,DATEFROMPARTS([moh_matm_delivery_year_nbr], [moh_matm_delivery_month_nbr], 15) as "end_date"
	   ,'Mothers age at birth' as "description"
	   ,moh_matm_mother_age_nbr as [value]
	   ,'moh maternity' AS [source]
FROM [IDI_Clean_20181020].[moh_clean].[maternity_mother]
WHERE [moh_matm_live_births_count_nbr] IN ('1','2','3','4');
GO

/* 
EVENT: Pregnancy
AUTHOR: ATHIRA NAIR
DATE: 4/12/2018
Intended use: Interval during which a woman is pregnant

Mother.
Recorded maternity events, by day of delivery, with number of live births
recorded. A value of zero means no live birth.

REVIEWED 2018-12-06 Simon
- used date of last period as pregnancy start
- added number of live births as value
- changed naming to reflect use as identification of time pregnant
2019-04-23 AK
- Need more information on the use of '15' as date in the query. 
- Need further inputs on use of 'NOT STATED' as filter
2019-04-26 SA
- Day of birth is unavailable in IDI 15 is used as middle of month as best estimate when a date is required
- 'NOT STATED' is to avoid still births, replaced by requiring positive number of live births
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_is_pregnant]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_is_pregnant];
GO

CREATE VIEW [DL-MAA2016-15].jt_is_pregnant AS
SELECT MOTHER_DATA.snz_uid
	   ,[moh_matm_last_mens_period_date] AS [start_date]
	   ,DATEFROMPARTS(MOTHER_DATA.moh_matm_delivery_year_nbr, MOTHER_DATA.moh_matm_delivery_month_nbr, 15) AS "end_date"
	   ,'Is pregnancy with num. live births' AS "description"
	   ,COALESCE([moh_matm_live_births_count_nbr], 0) as [value]
	   ,'moh maternity' AS [source]
FROM [IDI_Clean_20181020].[moh_clean].[maternity_mother] AS MOTHER_DATA
WHERE [moh_matm_live_births_count_nbr] IN ('1', '2', '3', '4') -- only live births
GO

/* 
EVENT: Pregnancy
AUTHOR: ATHIRA NAIR
DATE: 4/12/2018
Intended use: Identify number of previous children

Mother.
Recorded maternity events, by day of deliverey, with number of live births
recorded. A value of zero means no live birth.

REVIEWED 2018-12-06 Simon
- added number of live births as value
2019-04-23 AK
- Need further inputs on use of 'NOT STATED' as filter
2019-04-26 SA
- 'NOT STATED' is to avoid still births, replaced by requiring positive number of live births
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_live_births]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_live_births];
GO

CREATE VIEW [DL-MAA2016-15].jt_live_births AS
SELECT MOTHER_DATA.snz_uid
	   ,DATEFROMPARTS(MOTHER_DATA.moh_matm_delivery_year_nbr, MOTHER_DATA.moh_matm_delivery_month_nbr, 15) AS [start_date]
	   ,DATEFROMPARTS(MOTHER_DATA.moh_matm_delivery_year_nbr, MOTHER_DATA.moh_matm_delivery_month_nbr, 15) AS "end_date"
	   ,'gave birth to num. live births' AS "description"
	   ,COALESCE([moh_matm_live_births_count_nbr], 0) as [value]
	   ,'moh maternity' AS [source]
FROM [IDI_Clean_20181020].[moh_clean].[maternity_mother] AS MOTHER_DATA
WHERE [moh_matm_live_births_count_nbr] IN ('1', '2', '3', '4') -- only live births
GO

/*
EVENT: Lab tests
AUTHOR: ATHIRA NAIR
DATE: 4/12/2018
Intended use: Identification of lab test events, Identification of specific tests of concern

MOTHER, FATHER, WHANAU, BABY
Lab tests identified by code, joined to metadata codes (which contain duplicates)

The type of lab test conducted is given in the IDI metadata table [moh_test_code].
This lists ~300 types of lab test codes with their descriptions.

REVIEWED 2018-12-06 Simon
- joined lab test to metadata for test type
- added substring to shorten long classifications
2019-04-23 AK
- Need clarification on the availability of table metadata
2019-04-26 SA
- explanation of metadata table added to description
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_Lab_test]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_Lab_test];
GO

CREATE VIEW [DL-MAA2016-15].jt_Lab_test AS
SELECT lab_data.snz_uid
	   ,lab_data.moh_lab_visit_date as  "start_date"
	   ,lab_data.moh_lab_visit_date as "end_date"
	   ,'lab test' AS [description]
	   ,1 as [value]
	   ,'moh labs' AS [source]
FROM [IDI_Clean_20181020].[moh_clean].[lab_claims] AS lab_data
INNER JOIN (
	SELECT DISTINCT *
	FROM [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moh_test_code]
) b
ON lab_data.moh_lab_test_code = b.Code;
GO

/*
EVENT: Smoking indicator from Census 2013
AUTHOR: ATHIRA NAIR
DATE: 5/12/2018
Intended use: Identification of smoking in family

MOTHER, FATHER
Census asks for current of previous smoking behavior.

REVIEWED 2018-12-06 Simon
2019-04-23 AK
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_INDICATE_SMOKING]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_INDICATE_SMOKING];
GO

CREATE VIEW [DL-MAA2016-15].jt_INDICATE_SMOKING AS
SELECT CENSUS_DATA.snz_uid
       ,'2013-03-05' AS "start_date"
	   ,'2013-03-05' AS "end_date"
	   ,CASE WHEN [cen_ind_smoking_stus_code] LIKE '1' THEN 'REGULAR SMOKER'
			WHEN [cen_ind_smoking_stus_code] LIKE '2' THEN 'EX-SMOKER'  
			WHEN [cen_ind_smoking_stus_code] LIKE '3' THEN 'NEVER SMOKED REGULARLY'
			ELSE 'UNKNOWN'
			END AS [description]
       ,1 AS value
	   ,'census' AS [source]
FROM [IDI_Clean_20181020].[cen_clean].[census_individual] AS CENSUS_DATA
GO

/*
EVENT: Period in employment
AUTHOR: ATHIRA NAIR
DATE: 5/12/2018
Intended use: Identify periods of employment, identify wages and salaries earned

MOTHER, FATHER
Wages and Salaries paid to individuals per month as an indication of employment. Recorded start
and end dates used where available, otherwise employer month is used.

REVIEWED 2018-12-06 Simon
- switch to IRD EMS as monthly resolution
2019-04-23 AK
- More Information required on the use of specific date gap numbers in the query.
2019-04-26 SA
- day gap is to allow reporting of emploee start/end dates to be up to one month late. Larger gaps are assumed to be more likely caused by data errors
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_EMPLOYMENT_TIME]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_EMPLOYMENT_TIME];
GO

CREATE VIEW [DL-MAA2016-15].jt_EMPLOYMENT_TIME AS
SELECT snz_uid
       ,CASE WHEN [ir_ems_employee_start_date] IS NOT NULL
			AND [ir_ems_employee_start_date] < [ir_ems_return_period_date]
			AND DATEDIFF(DAY, [ir_ems_employee_start_date], [ir_ems_return_period_date]) < 60 THEN [ir_ems_employee_start_date] -- employee started in the last two months
		ELSE DATEFROMPARTS(YEAR([ir_ems_return_period_date]),MONTH([ir_ems_return_period_date]),1) END AS [start_date]
	   ,CASE WHEN [ir_ems_employee_end_date] IS NOT NULL
			AND [ir_ems_employee_end_date] < [ir_ems_return_period_date]
			AND DATEDIFF(DAY, [ir_ems_employee_end_date], [ir_ems_return_period_date]) < 27 THEN [ir_ems_employee_end_date] -- employee finished in the last month
		ELSE [ir_ems_return_period_date] END AS [end_date]
	   ,'Employed with W&S' as [description]
	   ,[ir_ems_gross_earnings_amt] as value
	   ,'ird ems' AS [source]
FROM [IDI_Clean_20181020].[ir_clean].[ird_ems]
WHERE [ir_ems_income_source_code]= 'W&S';
GO

/*
EVENT: Receipt of paid parental leave
AUTHOR: ATHIRA NAIR
DATE: 5/12/2018
Intended use: Identify period of paid parental leave, identify household earnings

MOTHER, FATHER
Paid parental leave received per month. Paid by government.
PPL can be claimed by either parent (in somecases by both) but this is more complex to arrange.

REVIEWED 2018-12-06 Simon
- Updated to follow employment pattern
2019-04-23 AK
- More Information required on the use of specific date gap numbers in the query.
2019-04-26 SA
- day gap is to allow reporting of emploee start/end dates to be up to one month late. Larger gaps are assumed to be more likely caused by data errors
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_PARENTAL_LEAVE]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_PARENTAL_LEAVE];
GO

CREATE VIEW [DL-MAA2016-15].[jt_PARENTAL_LEAVE] AS
SELECT snz_uid
       ,CASE WHEN [ir_ems_employee_start_date] IS NOT NULL
			AND [ir_ems_employee_start_date] < [ir_ems_return_period_date]
			AND DATEDIFF(DAY, [ir_ems_employee_start_date], [ir_ems_return_period_date]) < 60 THEN [ir_ems_employee_start_date] -- employee started in the last two months
		ELSE DATEFROMPARTS(YEAR([ir_ems_return_period_date]),MONTH([ir_ems_return_period_date]),1) END AS [start_date]
	   ,CASE WHEN [ir_ems_employee_end_date] IS NOT NULL
			AND [ir_ems_employee_end_date] < [ir_ems_return_period_date]
			AND DATEDIFF(DAY, [ir_ems_employee_end_date], [ir_ems_return_period_date]) < 27 THEN [ir_ems_employee_end_date] -- employee finished in the last month
		ELSE [ir_ems_return_period_date] END AS [end_date]
	   ,'Paid parental leave' as [description]
	   ,[ir_ems_gross_earnings_amt] as value
	   ,'ird ems' AS [source]
FROM [IDI_Clean_20181020].[ir_clean].[ird_ems]
WHERE [ir_ems_income_source_code]= 'PPL';
GO

/*
EVENT: Baby birth with birth weight
AUTHOR: ATHIRA NAIR
DATE: 5/12/2018
Intended use: Identify babies with very low birth weight

BABY
Birth weight of baby at time of birth

REVIEWED 2018-12-06 Simon
2019-04-23 AK
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_BIRTH_WEIGHT]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_BIRTH_WEIGHT];
GO

CREATE VIEW [DL-MAA2016-15].jt_BIRTH_WEIGHT AS
SELECT snz_uid
       ,DATEFROMPARTS([moh_matb_baby_birth_year_nbr], [moh_matb_baby_birth_month_nbr], '15') AS "start_date"
	   ,DATEFROMPARTS([moh_matb_baby_birth_year_nbr], [moh_matb_baby_birth_month_nbr], '15') AS "end_date"
	   ,'BIRTH WEIGHT' AS [description]
	   ,[moh_matb_birthweight_nbr] AS [value]
	   ,'moh maternity' AS [source]
FROM [IDI_Clean_20181020].[moh_clean].[maternity_baby]
WHERE [moh_matb_birthweight_nbr] IS NOT NULL
GO

/*
EVENT: Experience of a chronic condition
AUTHOR: Simon Anastasiadis
DATE: 2018-12-04
Intended use: Identification of periods where individuals suffer from chronic conditions

Specific chronic conditions as recorded by MOH.

REVIEWED: 
2019-04-23 AK
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_chronic_conditions]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_chronic_conditions];
GO

CREATE VIEW [DL-MAA2016-15].jt_chronic_conditions AS
SELECT [snz_uid]
	,[moh_chr_fir_incidnt_date] AS [start_date]
	,[moh_chr_last_incidnt_date] AS [end_date]
	,CASE WHEN [moh_chr_condition_text] = 'AMI' THEN 'acute myocardial infraction'
		WHEN [moh_chr_condition_text] = 'CAN' THEN 'cancer'
		WHEN [moh_chr_condition_text] = 'DIA' THEN 'diabetes'
		WHEN [moh_chr_condition_text] = 'GOUT' THEN 'gout'
		WHEN [moh_chr_condition_text] = 'STR' THEN 'stroke'
		WHEN [moh_chr_condition_text] = 'TBI' THEN 'traumatic brain injury' END AS [description]
	,1 AS value
	,'moh chronic' AS [source]
FROM [IDI_Clean_20181020].[moh_clean].[chronic_condition];
GO

/*
EVENT: Reward of a qualification
AUTHOR: Simon Anastasiadis
DATE: 2018-12-05
Intended use: Identification of highest qualification

Where only year is available assumed qualification awarded 1st December (approx, end of calendar year)
Code guided by Population Explorer Highest Qualification code in SNZ Population Explorer by Peter Elis
github.com/StatisticsNZ/population-explorer/blob/master/build-db/01-int-tables/18-qualificiations.sql

1 = Certificate or NCEA level 1
2 = Certificate or NCEA level 2
3 = Certificate or NCEA level 3
4 = certificate level 4
5 = Certificate of diploma level 5
6 = Certificate or diploma level 6
7 = Bachelors degree, graduate diploma or certificate level 7
8 = Bachelors honours degree or postgraduate diploma or certificate level 8
9 = Masters degree
10 = Doctoral degree

REVIEWED: awaiting feedback
2019-04-23 AK
- Further business info required on use of code filters for education level. There are levels like 00, 99 which have been excluded without any explanation.
2019-04-26 SA
- there are only 10 NZ qualification levels, values of 0 or 99 are assumed to be non-qualitication codes.
- Metadata gives 99 as unknown qualification level
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_qualification_awards]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_qualification_awards];
GO

CREATE VIEW [DL-MAA2016-15].jt_qualification_awards AS
SELECT snz_uid
		,award_date AS [start_date]
		,award_date AS [end_date]
		,'qual level awarded' AS [description]
		,qual AS [value]
		,'moe x3' AS [source]
FROM (
	-- Primary and secondary
	SELECT snz_uid
			,DATEFROMPARTS(moe_sql_attained_year_nbr,12,1) AS award_date
			,moe_sql_nqf_level_code AS qual
	FROM [IDI_Clean_20181020].[moe_clean].[student_qualification]

	UNION ALL

	-- Tertiary qualification
	SELECT snz_uid
			,DATEFROMPARTS(moe_com_year_nbr,12,1) AS award_date
			,moe_com_qual_level_code AS qual
	FROM [IDI_Clean_20181020].[moe_clean].[completion]
	WHERE moe_com_qual_level_code IS NOT NULL

	UNION ALL

	-- Industry traing qualifications
	SELECT snz_uid
			,moe_itl_end_date AS award_date
			,1 AS qual
	FROM IDI_Clean_20181020.moe_clean.tec_it_learner
	WHERE moe_itl_end_date IS NOT NULL
	AND moe_itl_level1_qual_awarded_nbr > 0

	UNION ALL

	SELECT snz_uid
			,moe_itl_end_date AS award_date
			,2 AS qual
	FROM IDI_Clean_20181020.moe_clean.tec_it_learner
	WHERE moe_itl_end_date IS NOT NULL
	AND moe_itl_level2_qual_awarded_nbr > 0

	UNION ALL

	SELECT snz_uid
			,moe_itl_end_date AS award_date
			,3 AS qual
	FROM IDI_Clean_20181020.moe_clean.tec_it_learner
	WHERE moe_itl_end_date IS NOT NULL
	AND moe_itl_level3_qual_awarded_nbr > 0

	UNION ALL

	SELECT snz_uid
			,moe_itl_end_date AS award_date
			,4 AS qual
	FROM IDI_Clean_20181020.moe_clean.tec_it_learner
	WHERE moe_itl_end_date IS NOT NULL
	AND moe_itl_level4_qual_awarded_nbr > 0

	UNION ALL

	SELECT snz_uid
			,moe_itl_end_date AS award_date
			,5 AS qual
	FROM IDI_Clean_20181020.moe_clean.tec_it_learner
	WHERE moe_itl_end_date IS NOT NULL
	AND moe_itl_level5_qual_awarded_nbr > 0

	UNION ALL

	SELECT snz_uid
			,moe_itl_end_date AS award_date
			,6 AS qual
	FROM IDI_Clean_20181020.moe_clean.tec_it_learner
	WHERE moe_itl_end_date IS NOT NULL
	AND moe_itl_level6_qual_awarded_nbr > 0

	UNION ALL

	SELECT snz_uid
			,moe_itl_end_date AS award_date
			,7 AS qual
	FROM IDI_Clean_20181020.moe_clean.tec_it_learner
	WHERE moe_itl_end_date IS NOT NULL
	AND moe_itl_level7_qual_awarded_nbr > 0

	UNION ALL

	SELECT snz_uid
			,moe_itl_end_date AS award_date
			,8 AS qual
	FROM IDI_Clean_20181020.moe_clean.tec_it_learner
	WHERE moe_itl_end_date IS NOT NULL
	AND moe_itl_level8_qual_awarded_nbr > 0

) all_awarded_qualitifications
WHERE qual IN (1,2,3,4,5,6,7,8,9,10); -- limit to 10 levels of NZQF
GO

/*
EVENT: T1 Benefit receipt by type
AUTHOR: Simon Anastasiadis
DATE: 2018-12-06
Intended use: Identify periods of Tier 1 benefit receipt.

Periods of tier 1 benefit receipt (main benefits). Generated by Marc de Boer's
SAS macros as incorporated into the SIAL. Not suited for calculating benefit amount
received but suited for duration of benefit.

REVIEWED:
2019-04-23 AK
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_benefit_period]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_benefit_period];
GO

CREATE VIEW [DL-MAA2016-15].jt_benefit_period AS
SELECT snz_uid
	,[start_date]
	,[end_date]
	,event_type_4 AS [description]
	,1 AS [value]
	,'msd T1 SIAL' AS [source]
FROM [IDI_Sandpit].[DL-MAA2016-15].SIAL_MSD_T1_events;
GO

/*
EVENT: Period on benefit
AUTHOR: Simon Anastasiadis
DATE: 2018-12-06
Intended use: Identify main benefit income received

Following same methodology as employment/wages and salaries, but for main benefit.
Suitable for computing income amount, but more accurate source exists for time
on benefit.

REVIEWED: awaiting feedback
2019-04-23 AK
- More Information required on the use of specific date gap numbers in the query.
2019-04-26 SA
- day gap is to allow reporting of emploee start/end dates to be up to one month late. Larger gaps are assumed to be more likely caused by data errors
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_benefit_amount]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_benefit_amount];
GO

CREATE VIEW [DL-MAA2016-15].jt_benefit_amount AS
SELECT snz_uid
       ,CASE WHEN [ir_ems_employee_start_date] IS NOT NULL
			AND [ir_ems_employee_start_date] < [ir_ems_return_period_date]
			AND DATEDIFF(DAY, [ir_ems_employee_start_date], [ir_ems_return_period_date]) < 60 THEN [ir_ems_employee_start_date] -- employee started in the last two months
		ELSE DATEFROMPARTS(YEAR([ir_ems_return_period_date]),MONTH([ir_ems_return_period_date]),1) END AS [start_date]
	   ,CASE WHEN [ir_ems_employee_end_date] IS NOT NULL
			AND [ir_ems_employee_end_date] < [ir_ems_return_period_date]
			AND DATEDIFF(DAY, [ir_ems_employee_end_date], [ir_ems_return_period_date]) < 27 THEN [ir_ems_employee_end_date] -- employee finished in last month
		ELSE [ir_ems_return_period_date] END AS [end_date]
	   ,'Income from benefit' as [description]
	   ,[ir_ems_gross_earnings_amt] as value
	   ,'ird ems' AS [source]
FROM [IDI_Clean_20181020].[ir_clean].[ird_ems]
WHERE [ir_ems_income_source_code]= 'BEN';
GO

/*
EVENT: Recent driver's license issue
AUTHOR: Simon Anastasiadis
DATE: 2018-12-06
Intended use: Identifying people who have a driver's license

Recent driver's license status for regular vehicles. Special licenses
(e.g. trucks, buses, etc.) deliberately excluded as they require a
regular license.
Not suited for identifying the time of license renewal/application.

REVIEWED: 
2019-04-23 AK
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_driver_license]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_driver_license];
GO

CREATE VIEW [DL-MAA2016-15].jt_driver_license AS
SELECT [snz_uid]
	,[nzta_dlr_licence_from_date] AS [start_date]
	,[nzta_dlr_licence_from_date] AS [end_date]
	,CONCAT('dlr status ',SUBSTRING([nzta_dlr_licence_stage_text], 1, 20)) AS [description]
	,1 AS [value]
	,'nzta license' AS [source]
FROM [IDI_Clean_20181020].[nzta_clean].[drivers_licence_register]
WHERE [nzta_dlr_licence_class_text] = 'MOTOR CARS AND LIGHT MOTOR VEHICLES'
GO

/*
EVENT: Latest vehicle registration
AUTHOR: Simon Anastasiadis
DATE: 2018-12-06
Intended use: Identify families with access to a vehicle

Vehicles with a recent/active registration. Explicitly excludes
trailers, but does include some non-typically vehicles such as
caravans, tractors, agricultural vehicles.
Not suited for identifying the time of vehicle registration.

REVIEWED:
2019-04-23 AK
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_vehicle_registration]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_vehicle_registration];
GO

CREATE VIEW [DL-MAA2016-15].jt_vehicle_registration AS
SELECT [snz_uid]
      ,[nzta_mvr_start_date] AS [start_date]
	  ,[nzta_mvr_end_date] AS [end_date]
	  ,'vehicle registration' AS [description]
	  ,1 AS [value]
	  ,'nzta registration' AS [source]
FROM [IDI_Clean_20181020].[nzta_clean].[motor_vehicle_register]
WHERE [nzta_mvr_body_type_text] NOT IN ('BOAT TRAILER', 'CAB AND CHASIS ONLY', 'CAB AND CHASSIS ONLY', 'DOMESTIC TRAILER',
									 'FLAT-DECK TRAILER', 'MOBILE MACHINE', 'NON HIGHWAY TRAILER-OTHER', 'OTHER COMMERCIAL TRAILER');
GO

/*
EVENT: Gap in benefit receipt
AUTHOR: Simon Anastasiadis
DATE: 2018-12-06
Intended use: Identify periods where benefits were temporarily stopped

Finds gaps of up to 23 days (three weeks + a weekend) in receipt of
the same benefit. Within the gap an individual is recorded as not receiving
the benefit they were receiving at the start and end of the gap.
Likely to be a point of stress for families due to having to visit WINZ.

Method can be extended to consider transitions between benefit types
(which likely indicate an interaction with WINZ) by removing the condition
that event_type_4 is the same.

Could be replaced by 'number of benefits started' as an indication of
interaction with WINZ.

REVIEWED:
2019-04-23 AK
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_benefit_gap]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_benefit_gap];
GO

CREATE VIEW [DL-MAA2016-15].jt_benefit_gap AS
SELECT *
FROM (
	SELECT a.snz_uid
		,a.[end_date] AS [start_date]
		,b.[start_date] AS [end_date]
		,CONCAT('days gap in ',SUBSTRING(a.event_type_4, 1, 20)) AS [description]
		,1 + DATEDIFF(DAY, a.[end_date], b.[start_date]) AS [value]
		,'msd T1 SIAL' AS [source]
	FROM [IDI_Sandpit].[DL-MAA2016-15].SIAL_MSD_T1_events a
	INNER JOIN [IDI_Sandpit].[DL-MAA2016-15].SIAL_MSD_T1_events b
	ON a.snz_uid = b.snz_uid
	AND a.event_type_4 = b.event_type_4
	AND a.[end_date] < b.[start_date]
) k
WHERE [value] > 0
AND [value] <= 23;
GO

/*
EVENT: A birth
AUTHOR: Simon Anastasiadis
DATE: 2018-12-06
Intended use: to calculate people's age as number of years elapsed

Birth dates from personal detail. As day of birth is not available
middle of month is used.

Unused as maternity record contains mother's age at birth.

REVIEWED: awaiting feedback
2019-04-23 AK
- The start_date is same as end_date. I believe end_date is just to have consistency for joining. Clarity required. 
2019-04-26 SA
- All measures require a start and end date, where no obvious end date exists we use end_date = start_date.
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_birth_dated]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_birth_dated];
GO

CREATE VIEW [DL-MAA2016-15].jt_birth_dated AS
SELECT [snz_uid]
      ,DATEFROMPARTS([snz_birth_year_nbr],[snz_birth_month_nbr],15) AS [start_date]
	  ,DATEFROMPARTS([snz_birth_year_nbr],[snz_birth_month_nbr],15) AS [end_date]
      ,'birth' AS [description]
	  ,1 AS [value]
	  ,'personal detail' AS [source]
FROM [IDI_Clean_20181020].[data].[personal_detail]
WHERE [snz_birth_year_nbr] IS NOT NULL;
GO

/*
EVENT: An interval where birth parents live together
AUTHOR: Simon Anastasiadis
DATE: 2018-12-06
Intended use: to calculate amount of time a baby's birth parents live together,
proxy for duration/stability of relationship

For a baby, the time intervals where both parents have the same recorded address.
Note that default address table is not well suited to this analysis, so this measure
is prone to error.

REVIEWED: awaiting feedback
- measure not in use due to concern that this measure is of low quality
  due to low quality of underlying address information
2019-04-23 AK
- Business logic is sound but is a description of logic required ?
2018-04-26 SA
- description added
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_parents_share_address]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_parents_share_address];
GO

CREATE VIEW [DL-MAA2016-15].jt_parents_share_address AS
SELECT a.snz_uid
	,CASE WHEN p1.ant_notification_date < p2.ant_notification_date THEN p2.ant_notification_date ELSE p1.ant_notification_date END AS [start_date] -- narrowest interval 
	,CASE WHEN p1.ant_replacement_date < p2.ant_replacement_date THEN p1.ant_replacement_date ELSE p2.ant_replacement_date END AS [end_date] -- when address periods overlap
	,'parents share address' AS [description]
	,p1.snz_idi_address_register_uid AS [value]
	,'dia and address' AS [source]
FROM [IDI_Clean_20181020].[dia_clean].[births] a
INNER JOIN [IDI_Clean_20181020].[data].[address_notification] p1 -- address of parent 1
ON a.parent1_snz_uid = p1.snz_uid
INNER JOIN [IDI_Clean_20181020].[data].[address_notification] p2 -- address of parent 2
ON a.parent2_snz_uid = p2.snz_uid
AND p1.snz_idi_address_register_uid = p2.snz_idi_address_register_uid -- both parents share an address
AND p1.ant_notification_date < p2.ant_replacement_date -- address periods overlap
AND p2.ant_notification_date < p1.ant_replacement_date -- address periods overlap
WHERE a.parent1_snz_uid IS NOT NULL
AND a.parent2_snz_uid IS NOT NULL;
GO

/*
EVENT: Duration at address scored with number of others at address
AUTHOR: Simon Anastasiadis
DATE: 2018-12-06
Intended use: as measure of stability of housing

During tenure at an address, gives the number of people (self included)
who lived at the address for some period during your tenure.
Given the possibility of 'new move in' being observed before 'old move out'
we shrink the address tenure for the purposes of identifying overlap.

REVIEWED: awaiting review
- measure not in use due to concern that this measure is of low quality
  due to low quality of underlying address information
2019-04-23 AK
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_address_sharing]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_address_sharing];
GO

CREATE VIEW [DL-MAA2016-15].jt_address_sharing AS 
SELECT main.snz_uid
	,main.ant_notification_date AS [start_date]
	,main.ant_replacement_date AS [end_date]
	,'people through your address' AS [description]
	,count(DISTINCT guest.snz_uid) AS [value]
	,'address' AS [source]
FROM [IDI_Clean_20181020].[data].[address_notification] main
INNER JOIN [IDI_Clean_20181020].[data].[address_notification] guest
ON main.snz_idi_address_register_uid = guest.snz_idi_address_register_uid
AND DATEADD(DAY, 14, main.ant_notification_date) < guest.ant_replacement_date
AND guest.ant_notification_date < DATEADD(DAY,-14, main.ant_replacement_date)
GROUP BY main.snz_uid, main.ant_notification_date, main.ant_replacement_date;
GO

/*
EVENT:  Address change
AUTHOR: Simon Anastasiadis
DATE: 2018-12-06
Intended use: indicator of moving into a new address

Identifies notifications at a new address. Given that notifications do not
always represent a new address, we require that the individual has no
notifications at the same address within the last 45 days.

REVIEWED: 
2019-04-23 AK
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_address_change]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_address_change];
GO

CREATE VIEW [DL-MAA2016-15].jt_address_change AS 
SELECT DISTINCT a.snz_uid
	,a.ant_notification_date AS [start_date]
	,a.ant_notification_date AS [end_date]
	,'address change to' AS [description]
	,a.snz_idi_address_register_uid AS [value]
	,'address' AS [source]
FROM [IDI_Clean_20181020].[data].[address_notification] a
LEFT JOIN [IDI_Clean_20181020].[data].[address_notification] b
ON a.snz_uid = b.snz_uid
AND a.snz_idi_address_register_uid = b.snz_idi_address_register_uid
WHERE b.snz_idi_address_register_uid IS NULL
OR DATEDIFF(DAY, b.ant_notification_date, a.ant_notification_date) > 45
GO

/*
EVENT: Attendance of a drug and alcohol program
AUTHOR: Simon Anastasiadis
DATE: 2018-12-07
Intended use: identification of receipt of drug & alcohol support

Gives time periods (often single days) that an individual was recorded
as at a drug and alcohol program. Reports are provided by DHBs and NGOs
on services rendered (hence we assume non-attendance is not captured).
Reporting by NGOs has been progressive from 2008 to 2014. Hence counts
over time will vary with increased reporting/connection of NGO reports
to PRIMHD.
Code of the team providing the program is given as the value. For
confidentiality we must ensure at least two team codes are used.

REVIEWED: 
2019-04-23 AK
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_alcohol_drug_team]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_alcohol_drug_team];
GO

CREATE VIEW [DL-MAA2016-15].jt_alcohol_drug_team AS
SELECT [snz_uid]
	,[moh_mhd_activity_start_date] AS [start_date]
	,[moh_mhd_activity_end_date] AS [end_date]
	,'program with alcohol and drug team' AS [description]
	,[moh_mhd_team_code] AS [value]
	,'primhd' AS [source]
FROM [IDI_Clean_20181020].[moh_clean].[PRIMHD]
INNER JOIN [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moh_primhd_team_code]
ON moh_mhd_team_code = TEAM_CODE
WHERE TEAM_TYPE_DESCRIPTION = 'Alcohol and Drug Team'
GO

/*
EVENT: Maternal mental health program attendance
AUTHOR: Simon Anastasiadis
DATE: 2018-12-07
Intended use: identification of receipt of maternal mental health support service

Gives time periods (often single days) that an individual was recorded
as at a maternity mental health program. Reports are provided by DHBs and NGOs
on services rendered (hence we assume non-attendance is not captured).
Reporting by NGOs has been progressive from 2008 to 2014. Hence counts
over time will vary with increased reporting/connection of NGO reports
to PRIMHD.
Code of the team providing the program is given as the value. For
confidentiality we must ensure at least two team codes are used.

REVIEWED: 
2019-04-23 AK
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_maternal_MH_team]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_maternal_MH_team];
GO

CREATE VIEW [DL-MAA2016-15].jt_maternal_MH_team AS
SELECT [snz_uid]
	,[moh_mhd_activity_start_date] AS [start_date]
	,[moh_mhd_activity_end_date] AS [end_date]
	,'program with maternal MH team' AS [description]
	,[moh_mhd_team_code] AS [value]
	,'primhd' AS [source]
FROM [IDI_Clean_20181020].[moh_clean].[PRIMHD]
INNER JOIN [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moh_primhd_team_code]
ON moh_mhd_team_code = TEAM_CODE
WHERE TEAM_TYPE_DESCRIPTION = 'Maternal Mental Health Team'
GO

/*
EVENT: Contact with Primary Health Organisation
AUTHOR: Simon Anastasiadis
DATE: 2018-12-07
Intended use: Identification of primary health use

PHO enrollments contains interactions with primary health organisations for
those people who are enrolled or registered (non-citizens can only register)
with a GP as their regular practitioner.
GMS contain subsidies to GPs for visits by non-enrolled, non-registered
patients.
PHO enrollments are reported quarterly. This means that where there are multiple
visits within the same quarter, only the last visit is reported.

REVIEWED: awaiting feedback
2019-04-23 AK
- Should we ignore Null dates ?
2019-04-26 SA
- NULL dates excluded
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_primary_health]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_primary_health];
GO

CREATE VIEW [DL-MAA2016-15].jt_primary_health AS
SELECT DISTINCT [snz_uid]
      ,[moh_gms_visit_date] AS [start_date]
	  ,[moh_gms_visit_date] AS [end_date]
	  ,'non-enrolled PHO contact' As [description]
	  ,1 AS [value]
	  ,'moh gms' AS [source]
FROM [IDI_Clean_20181020].[moh_clean].[gms_claims]
WHERE [moh_gms_visit_date] IS NOT NULL

UNION ALL

SELECT DISTINCT [snz_uid]
      ,[moh_pho_last_consul_date] AS [start_date]
	  ,[moh_pho_last_consul_date] AS [end_date]
	  ,'enrolled PHO contact' AS [description]
	  ,1 AS [value]
	  ,'moh pho' AS [source]
FROM [IDI_Clean_20181020].[moh_clean].[pho_enrolment]
WHERE [moh_pho_last_consul_date] IS NOT NULL;
GO

/*
EVENT: Active registration with a Primary Health Organisation
AUTHOR: Simon Anastasiadis
DATE: 2018-12-07
Intended use: Identification of primary health use

Intervals within which an individual is making active use of the PHO
they are registered with. Interval runs from date of registration, until
the date of their last visit at the PHO (associated with their 
registration date, so a new registration creates a new interval).

REVIEWED: awaiting review
- practice id removed as contains non-numeric
- Registration may not be meaningful as deregistration requires 2-3 years
  with no contact between individual and PHO
2019-04-23 AK
- Should we handle NULL values in the dates ? Does it have an impact on how we get insights?
2019-04-26 SA
- NULL dates excluded
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_pho_registration]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_pho_registration];
GO

CREATE VIEW [DL-MAA2016-15].jt_pho_registration AS
SELECT [snz_uid]
	,[moh_pho_enrolment_date] AS [start_date]
	,MAX([moh_pho_last_consul_date]) AS [end_date]
	,'active PHO use' AS [description]
	,1 AS [value]
	,'moh pho' AS [source]
FROM [IDI_Clean_20181020].[moh_clean].[pho_enrolment]
WHERE [moh_pho_enrolment_date] IS NOT NULL
AND [moh_pho_last_consul_date] IS NOT NULL
GROUP BY [snz_uid], [moh_pho_enrolment_date], [moh_pho_practice_id];
GO

/*
AUTHOR: Simon Anastasiadis
DATE: 2018-12-07

Before school check simple classification for ease of further events.

REVIEWED: 
2019-04-23 AK
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_simple_b4sc_outcomes]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_simple_b4sc_outcomes];
GO

CREATE VIEW [DL-MAA2016-15].jt_simple_b4sc_outcomes AS
SELECT [snz_uid]
	,[moh_bsc_check_date] AS [check_date]
	,[moh_bsc_check_consent_text] AS [parent_consent]
	,CASE WHEN [moh_bsc_general_outcome_text] = 'Not Referred' THEN 'pass'
			WHEN [moh_bsc_general_outcome_text] = 'Declined' THEN 'declined'
			WHEN [moh_bsc_general_outcome_text] IS NOT NULL THEN 'need'
			ELSE NULL END AS [general_outcome]
	,CASE WHEN [moh_bsc_vision_outcome_text] = 'Pass Bilaterally' THEN 'pass'
			WHEN [moh_bsc_vision_outcome_text] = 'Decline' THEN 'declined'
			WHEN [moh_bsc_vision_outcome_text] IS NOT NULL THEN 'need'
			ELSE NULL END AS [vision_outcome]
	,CASE WHEN [moh_bsc_hearing_outcome_text] = 'Pass Bilaterally' THEN 'pass'
			WHEN [moh_bsc_hearing_outcome_text] = 'Decline' THEN 'declined'
			WHEN [moh_bsc_hearing_outcome_text] IS NOT NULL THEN 'need'
			ELSE NULL END AS [hearing_outcome]
	,CASE WHEN [moh_bsc_growth_outcome_text] = 'Not Referred' THEN 'pass'
			WHEN [moh_bsc_growth_outcome_text] = 'Declined' THEN 'declined'
			WHEN [moh_bsc_growth_outcome_text] IS NOT NULL THEN 'need'
			ELSE NULL END AS [growth_outcome]
	,CASE WHEN [moh_bsc_dental_outcome_text] = 'Not Referred' THEN 'pass'
			WHEN [moh_bsc_dental_outcome_text] = 'Declined' THEN 'declined'
			WHEN [moh_bsc_dental_outcome_text] IS NOT NULL THEN 'need'
			ELSE NULL END AS [dental_outcome]
	,CASE WHEN [moh_bsc_imms_outcome_text] = 'Already Immunised' THEN 'pass'
			WHEN [moh_bsc_imms_outcome_text] = 'Declined' THEN 'declined'
			WHEN [moh_bsc_imms_outcome_text] IS NOT NULL THEN 'need'
			ELSE NULL END AS [immunised_outcome]
	,CASE WHEN [moh_bsc_peds_outcome_text] = 'Not Referred' THEN 'pass'
			WHEN [moh_bsc_peds_outcome_text] = 'Declined' THEN 'declined'
			WHEN [moh_bsc_peds_outcome_text] IS NOT NULL THEN 'need'
			ELSE NULL END AS [development_outcome]
	,CASE WHEN [moh_bsc_sdqp_outcome_text] = 'Not Referred' THEN 'pass'
			WHEN [moh_bsc_sdqp_outcome_text] = 'Declined' THEN 'declined'
			WHEN [moh_bsc_sdqp_outcome_text] IS NOT NULL THEN 'need'
			ELSE NULL END AS [behavior_p_outcome]
	,CASE WHEN [moh_bsc_sdqt_outcome_text] = 'Not Referred' THEN 'pass'
			WHEN [moh_bsc_sdqt_outcome_text] = 'Declined' THEN 'declined'
			WHEN [moh_bsc_sdqt_outcome_text] IS NOT NULL THEN 'need'
			ELSE NULL END AS [behavior_t_outcome]
FROM [IDI_Clean_20181020].[moh_clean].[b4sc]
WHERE [moh_bsc_check_status_text] IN ('Closed', 'Completed');
GO

/*
EVENT: B4 School check identified a need
AUTHOR: Simon Anastasiadis
DATE: 2018-12-07
Intended use: Identification of child developmental needs, identification of parents'
willingness to engage with the system

Immunisation, developmental (PEDS) and behavioral (SDQ) needs identified by before
school check.
B4SC also identify other kinds of need. These are prepared in the simple_b4sc view
but not currently provided as events.

REVIEWED: 2019-03-20 - AK Sandpit table [DL-MAA2016-15].[jt_simple_b4sc_outcomes] not available,
query updated to fetch required content from the IDI_Clean tables. In the description, the 
author has mentioned Immunisation in the description which is not captured in the query. Confirmation 
required on the addition of immunisation to the views.
2019-04-01 SA Not sandpit table, target table is the view above in [IDI_UserCode]
2019-04-23 AK
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_b4sc_need]','V') IS NOT NULL                                  
DROP VIEW [DL-MAA2016-15].[jt_b4sc_need];
GO

CREATE VIEW [DL-MAA2016-15].jt_b4sc_need AS
SELECT snz_uid
	,[check_date] AS [start_date]
	,[check_date] AS [end_date]
	,CONCAT('development ', [development_outcome]) AS [description]
	,1 AS [value]
	,'moh b4sc' AS [source]
FROM [IDI_UserCode].[DL-MAA2016-15].jt_simple_b4sc_outcomes
WHERE [development_outcome] IS NOT NULL

UNION ALL

SELECT snz_uid
	,[check_date] AS [start_date]
	,[check_date] AS [end_date]
	,CONCAT('behavior_p ', [behavior_p_outcome]) AS [description]
	,1 AS [value]
	,'moh b4sc' AS [source]
FROM [IDI_UserCode].[DL-MAA2016-15].jt_simple_b4sc_outcomes
WHERE [behavior_p_outcome] IS NOT NULL

UNION ALL

SELECT snz_uid
	,[check_date] AS [start_date]
	,[check_date] AS [end_date]
	,CONCAT('behavior_t ', [behavior_t_outcome]) AS [description]
	,1 AS [value]
	,'moh b4sc' AS [source]
FROM [IDI_UserCode].[DL-MAA2016-15].jt_simple_b4sc_outcomes
WHERE [behavior_t_outcome] IS NOT NULL
GO

/*
EVENT: Number of previous pregnancies
AUTHOR: Simon Anastasiadis
DATE: 2019-01-08
Intended use: To give sense of mother's gestation history

REVIEWED: 
2019-04-23 AK
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_prev_pregnancy]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_prev_pregnancy];
GO

CREATE VIEW [DL-MAA2016-15].jt_prev_pregnancy AS
SELECT snz_uid
	,DATEFROMPARTS([moh_matm_delivery_year_nbr], [moh_matm_delivery_month_nbr], 15) AS [start_date]
	,DATEFROMPARTS([moh_matm_delivery_year_nbr], [moh_matm_delivery_month_nbr], 15) AS [end_date]
	,'previous pregnancies' AS [description]
	,[moh_matm_gravida_nbr] AS [value]
	,'moh maternity' AS [source]
FROM [IDI_Clean_20181020].[moh_clean].[maternity_mother]
WHERE [moh_matm_gravida_nbr] IS NOT NULL
AND snz_uid IS NOT NULL
AND [moh_matm_delivery_year_nbr] IS NOT NULL
AND [moh_matm_delivery_month_nbr] IS NOT NULL;
GO

/*
EVENT: Previous completed pregnancies
AUTHOR: Simon Anastasiadis
DATE: 2019-01-08
Intended use: To give sense of mother's gestation history

REVIEWED: 
2019-04-23 AK
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_prev_completed_pregnancy]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_prev_completed_pregnancy];
GO

CREATE VIEW [DL-MAA2016-15].jt_prev_completed_pregnancy AS
SELECT snz_uid
	,DATEFROMPARTS([moh_matm_delivery_year_nbr], [moh_matm_delivery_month_nbr], 15) AS [start_date]
	,DATEFROMPARTS([moh_matm_delivery_year_nbr], [moh_matm_delivery_month_nbr], 15) AS [end_date]
	,'previous completed pregnancies' AS [description]
	,[moh_matm_parity_nbr] AS [value]
	,'moh maternity' AS source
FROM [IDI_Clean_20181020].[moh_clean].[maternity_mother]
WHERE [moh_matm_parity_nbr] IS NOT NULL
AND snz_uid IS NOT NULL
AND [moh_matm_delivery_year_nbr] IS NOT NULL
AND [moh_matm_delivery_month_nbr] IS NOT NULL;
GO

/*
EVENT: Indicator for concern for tobacco during pregnancy
AUTHOR: Simon Anastasiadis
DATE: 2019-01-08
Intended use: Indicator of mother's smoking risk/behaviour

REVIEWED: 
2019-04-23 AK
2019-04-26 SA
- exclude records where value = 0
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_pregnancy_smoking]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_pregnancy_smoking];
GO

CREATE VIEW [DL-MAA2016-15].jt_pregnancy_smoking AS
SELECT *
FROM (
	SELECT snz_uid
		,DATEFROMPARTS([moh_matm_delivery_year_nbr], [moh_matm_delivery_month_nbr], 15) AS [start_date]
		,DATEFROMPARTS([moh_matm_delivery_year_nbr], [moh_matm_delivery_month_nbr], 15) AS [end_date]
		,'maternity tobacco concern' AS [description]
		,CASE WHEN [moh_matm_smok_st_frst_pcp_rg_ind] = 'Y' THEN 1 ELSE 0 END
		+CASE WHEN [moh_matm_counsllng_tobac_use_ind] = 'Y' THEN 1 ELSE 0 END
		+CASE WHEN [moh_matm_smking_stat_at_2wks_ind] = 'Y' THEN 1 ELSE 0 END AS [value]
		,'moh maternity' AS source
	FROM [IDI_Clean_20181020].[moh_clean].[maternity_mother]
	WHERE snz_uid IS NOT NULL
	AND [moh_matm_delivery_year_nbr] IS NOT NULL
	AND [moh_matm_delivery_month_nbr] IS NOT NULL
) k
WHERE [value] > 0;
GO

/*
EVENT: Antenatal complications
AUTHOR: Simon Anastasiadis
DATE: 2019-01-08
Intended use: Indication for a hard pregnancy

REVIEWED: 
2019-04-23 AK
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_complications_antenatal]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_complications_antenatal];
GO

CREATE VIEW [DL-MAA2016-15].jt_complications_antenatal AS
SELECT snz_uid
	,DATEFROMPARTS([moh_matm_delivery_year_nbr], [moh_matm_delivery_month_nbr], 15) AS [start_date]
	,DATEFROMPARTS([moh_matm_delivery_year_nbr], [moh_matm_delivery_month_nbr], 15) AS [end_date]
	,'number of concerns during pregnancy' AS [description]
	,CASE WHEN [moh_matm_threat_mscrrge_abrt_ind] = 'Y' THEN 1 ELSE 0 END -- concern for miscarriage
	+CASE WHEN [moh_matm_preclmpsia_eclmpsia_ind] = 'Y' THEN 1 ELSE 0 END -- high blood pressure due to pregnancy
	+CASE WHEN [moh_matm_icu_drng_antnt_admt_ind] = 'Y' THEN 1 ELSE 0 END -- ICU in antenatal
	+CASE WHEN [moh_matm_antenatal_admits_nbr] > 2 THEN 1 ELSE 0 END -- more than 2 antenatal admints
	+CASE WHEN [moh_matm_obstrc_antenat_admt_nbr] > 2 THEN 1 ELSE 0 END AS [value] -- obstetric in antenatal
	,'moh maternity' AS source
FROM [IDI_Clean_20181020].[moh_clean].[maternity_mother]
WHERE snz_uid IS NOT NULL
AND [moh_matm_delivery_year_nbr] IS NOT NULL
AND [moh_matm_delivery_month_nbr] IS NOT NULL;
GO

/*
EVENT: Complications at birth
AUTHOR: Simon Anastasiadis
DATE: 2019-01-08
Intended use: Indication of a hard birth

REVIEWED: 
2019-04-23 AK
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_complications_birth]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_complications_birth];
GO

CREATE VIEW [DL-MAA2016-15].jt_complications_birth AS
SELECT snz_uid
	,DATEFROMPARTS([moh_matm_delivery_year_nbr], [moh_matm_delivery_month_nbr], 15) AS [start_date]
	,DATEFROMPARTS([moh_matm_delivery_year_nbr], [moh_matm_delivery_month_nbr], 15) AS [end_date]
	,'number of concerns at birth' AS [description]
	,CASE WHEN [moh_matm_icu_admt_drng_dlvry_ind] = 'Y' THEN 1 ELSE 0 END -- ICU admit during delivery
	+CASE WHEN [moh_matm_pstprtum_hmorrhge_ind] = 'Y' THEN 1 ELSE 0 END -- hemorage
	+CASE WHEN [moh_matm_blood_transfusion_ind] = 'Y' THEN 1 ELSE 0 END -- blood transfussion required
	+CASE WHEN [moh_matm_genrl_ana_for_caesr_ind] = 'Y' THEN 1 ELSE 0 END -- general anathetic required
	+CASE WHEN [moh_matm_surg_repair_tear_ind] = 'Y' THEN 1 ELSE 0 END -- surgical repair of tear
	+CASE WHEN [moh_matm_man_removl_plcnta_ind] = 'Y' THEN 1 ELSE 0 END -- manual removal of placenta
	+CASE WHEN [moh_matm_degree_of_tear_text] IN ('FOURTH', 'THIRD') THEN 1 ELSE 0 END -- serious tear
	+CASE WHEN [moh_matm_nmd_length_of_stay_nbr] > 7 THEN 1 ELSE 0 END -- long hospital stay
	+CASE WHEN [moh_matm_emergency_caesarean_ind] = 'Y' THEN 1 ELSE 0 END -- emergency caesarian
	+CASE WHEN [moh_matm_spontaneous_breech_ind] = 'Y' THEN 1 ELSE 0 END  -- breech
	+CASE WHEN [moh_matm_assisted_breech_ind] = 'Y' THEN 1 ELSE 0 END -- breech
	+CASE WHEN [moh_matm_breech_extraction_ind] = 'Y' THEN 1 ELSE 0 END -- breech
	+CASE WHEN [moh_matm_forceps_ind] = 'Y' THEN 1 ELSE 0 END  -- forceps required for delivery
	+CASE WHEN [moh_matm_vacuum_ind] = 'Y' THEN 1 ELSE 0 END  -- vacuum required for delivery
	+CASE WHEN [moh_matm_forceps_and_vacuum_ind] = 'Y' THEN 1 ELSE 0 END  -- forceps and vacuum required for delivery
	+CASE WHEN [moh_matm_spontaneous_vertex_ind] = 'Y' THEN 1 ELSE 0 END AS [value] -- vertex
,'moh maternity' AS source
FROM [IDI_Clean_20181020].[moh_clean].[maternity_mother]
WHERE snz_uid IS NOT NULL
AND [moh_matm_delivery_year_nbr] IS NOT NULL
AND [moh_matm_delivery_month_nbr] IS NOT NULL;
GO

/*
EVENT: Support post birth
AUTHOR: Simon Anastasiadis
DATE: 2019-01-08
Intended use: Number of contacts with Lead Maternity Carer (LMC) post-birth

REVIEWED:
2019-04-23 AK
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_support_postnatal]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_support_postnatal];
GO

CREATE VIEW [DL-MAA2016-15].jt_support_postnatal AS
SELECT snz_uid
	,DATEFROMPARTS([moh_matm_delivery_year_nbr], [moh_matm_delivery_month_nbr], 15) AS [start_date]
	,DATEFROMPARTS([moh_matm_delivery_year_nbr], [moh_matm_delivery_month_nbr], 15) AS [end_date]
	,'number of contacts with LMC postnatal' AS [description]
	,[moh_matm_lmc_contacts_nbr] AS [value] -- LMC contact count
	,'moh maternity' AS source
FROM [IDI_Clean_20181020].[moh_clean].[maternity_mother]
WHERE snz_uid IS NOT NULL
AND [moh_matm_delivery_year_nbr] IS NOT NULL
AND [moh_matm_delivery_month_nbr] IS NOT NULL
AND [moh_matm_lmc_contacts_nbr] IS NOT NULL;
GO

/* Support pre-birth
EVENT: 
AUTHOR: Simon Anastasiadis
DATE: 2019-01-08
Intended use: Number of contacts with LMC pre-birth

REVIEWED:
2019-04-23 AK
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_support_antenatal]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_support_antenatal];
GO

CREATE VIEW [DL-MAA2016-15].jt_support_antenatal AS
SELECT snz_uid
	,DATEFROMPARTS([moh_matm_delivery_year_nbr], [moh_matm_delivery_month_nbr], 15) AS [start_date]
	,DATEFROMPARTS([moh_matm_delivery_year_nbr], [moh_matm_delivery_month_nbr], 15) AS [end_date]
	,'number of contacts with LMC antenatal' AS [description]
	,[moh_matm_lmc_antenatal_cont_nbr] AS [value] -- LMC contact count
	,'moh maternity' AS source
FROM [IDI_Clean_20181020].[moh_clean].[maternity_mother]
WHERE snz_uid IS NOT NULL
AND [moh_matm_delivery_year_nbr] IS NOT NULL
AND [moh_matm_delivery_month_nbr] IS NOT NULL
AND [moh_matm_lmc_antenatal_cont_nbr] IS NOT NULL;
GO

/*
EVENT: Registration with Lead Maternity Carer (LMC)
AUTHOR: Simon Anastasiadis
DATE: 2019-01-08
Intended use: Indicates data of LMC registration

While number of LMC contacts is recorded, only the date of registration
is recorded.

REVIEWED: 
2019-04-23 AK
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_LMC_registration]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_LMC_registration];
GO

CREATE VIEW [DL-MAA2016-15].jt_LMC_registration AS
SELECT snz_uid
	,[moh_matm_first_pcp_reg_date] AS [start_date]
	,[moh_matm_first_pcp_reg_date] AS [end_date]
	,'registration with (first) primary care provider' AS [description]
	,1 AS [value]
	,'moh maternity' AS source
FROM [IDI_Clean_20181020].[moh_clean].[maternity_mother]
WHERE snz_uid IS NOT NULL
AND [moh_matm_delivery_year_nbr] IS NOT NULL
AND [moh_matm_delivery_month_nbr] IS NOT NULL
AND [moh_matm_first_pcp_reg_date] IS NOT NULL;
GO

/*
EVENT: Partial employment
AUTHOR: Simon Anastasiadis
DATE: 5/12/2018
Intended use: Identify periods of employment likely to be part-time

MOTHER, FATHER
Wages and Salaries paid to individuals per month as an indication of employment. Recorded start
and end dates used where available, otherwise employer month is used.
Minimum wage * 40 hours * 4 weeks is used as the threshold for partial/full employment

REVIEWED: awaiting feedback
2019-04-23 AK
- Need some more confirmation on the business logic based on age.
2019-04-26 SA
- "age" was a typo, should read "wage"
- explanation of 60 & 27 days gap added in line with other IRD EMS views
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_employment_partial]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_employment_partial];
GO

CREATE VIEW [DL-MAA2016-15].jt_employment_partial AS
SELECT snz_uid
       ,CASE WHEN [ir_ems_employee_start_date] IS NOT NULL
			AND [ir_ems_employee_start_date] < [ir_ems_return_period_date]
			AND DATEDIFF(DAY, [ir_ems_employee_start_date], [ir_ems_return_period_date]) < 60 THEN [ir_ems_employee_start_date] -- employee started in the last two months
		ELSE DATEFROMPARTS(YEAR([ir_ems_return_period_date]),MONTH([ir_ems_return_period_date]),1) END AS [start_date]
	   ,CASE WHEN [ir_ems_employee_end_date] IS NOT NULL
			AND [ir_ems_employee_end_date] < [ir_ems_return_period_date]
			AND DATEDIFF(DAY, [ir_ems_employee_end_date], [ir_ems_return_period_date]) < 27 THEN [ir_ems_employee_end_date] -- employee finished in the last month
		ELSE [ir_ems_return_period_date] END AS [end_date]
	   ,'Partial employment with W&S' as [description]
	   ,1 as value
	   ,'ird ems' AS [source]
FROM [IDI_Clean_20181020].[ir_clean].[ird_ems]
WHERE [ir_ems_income_source_code]= 'W&S'
AND [ir_ems_gross_earnings_amt] < 2640;
GO

/*
EVENT: Full employment
AUTHOR: Simon Anastasiadis
DATE: 5/12/2018
Intended use: Identify periods of employment likely to be full-time

MOTHER, FATHER
Wages and Salaries paid to individuals per month as an indication of employment. Recorded start
and end dates used where available, otherwise employer month is used.
Minimum wage * 40 hours * 4 weeks is used as the threshold for partial/full employment

REVIEWED: awaiting feedback
2019-04-23 AK
- Need some more confirmation on the business logic based on age.
2019-04-26 SA
- "age" was a typo, should read "wage"
- explanation of 60 & 27 days gap added in line with other IRD EMS views
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_employment_full]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_employment_full];
GO

CREATE VIEW [DL-MAA2016-15].jt_employment_full AS
SELECT snz_uid
       ,CASE WHEN [ir_ems_employee_start_date] IS NOT NULL
			AND [ir_ems_employee_start_date] < [ir_ems_return_period_date]
			AND DATEDIFF(DAY, [ir_ems_employee_start_date], [ir_ems_return_period_date]) < 60 THEN [ir_ems_employee_start_date] -- employee started in the last two months
		ELSE DATEFROMPARTS(YEAR([ir_ems_return_period_date]),MONTH([ir_ems_return_period_date]),1) END AS [start_date]
	   ,CASE WHEN [ir_ems_employee_end_date] IS NOT NULL
			AND [ir_ems_employee_end_date] < [ir_ems_return_period_date]
			AND DATEDIFF(DAY, [ir_ems_employee_end_date], [ir_ems_return_period_date]) < 27 THEN [ir_ems_employee_end_date] -- employee finished in the last month
		ELSE [ir_ems_return_period_date] END AS [end_date]
	   ,'Full employment with W&S' as [description]
	   ,1 as value
	   ,'ird ems' AS [source]
FROM [IDI_Clean_20181020].[ir_clean].[ird_ems]
WHERE [ir_ems_income_source_code]= 'W&S'
AND [ir_ems_gross_earnings_amt] >= 2640;
GO

/*
EVENT: Emergency department visit
AUTHOR: Simon Anastasiadis
DATE: 2019-01-08
Intended use: Identify ED visit events

We use ED visits as recorded in out patients. As per Craig's advice:
because we are only interested in counting events, we do not need to
combine with admitted patient ED events.
Events where the person Did Not Attend (DNA) are excluded.

REVIEWED: 
2019-04-23 AK
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_emergency_department]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_emergency_department];
GO

CREATE VIEW [DL-MAA2016-15].jt_emergency_department AS
SELECT [snz_uid]
      ,[moh_nnp_service_date] AS [start_date]
	  ,[moh_nnp_service_date] AS [end_date]
	  ,'ED visit' AS [description]
	  ,1 AS [value]
	  ,'moh nnpac' as [source]
FROM [IDI_Clean_20181020].[moh_clean].[nnpac]
WHERE [moh_nnp_event_type_code] = 'ED'
AND [moh_nnp_service_date] IS NOT NULL
AND [moh_nnp_attendence_code] <> 'DNA';
GO

/*
EVENT: out-patient hospital visit
AUTHOR: Simon Anastasiadis
DATE: 2019-01-08
Intended use: Identify hospital visit events

We use hospital visits as recorded in out patients.
Events where the person Did Not Attend (DNA) are excluded.

REVIEWED: 
2019-04-23 AK
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_out_patient]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_out_patient];
GO

CREATE VIEW [DL-MAA2016-15].jt_out_patient AS
SELECT [snz_uid]
      ,[moh_nnp_service_date] AS [start_date]
	  ,[moh_nnp_service_date] AS [end_date]
	  ,'out patient visit' AS [description]
	  ,1 AS [value]
	  ,'moh nnpac' as [source]
FROM [IDI_Clean_20181020].[moh_clean].[nnpac]
WHERE [moh_nnp_event_type_code] = 'OP'
AND [moh_nnp_service_date] IS NOT NULL
AND [moh_nnp_attendence_code] <> 'DNA';
GO

/*
EVENT: community visit by hospital based practitioner
AUTHOR: Simon Anastasiadis
DATE: 2019-01-08
Intended use: Identify health interaction events

We use community visits by hospital staff as recorded in out patients.
Craig notes that these have only been consistently recorded recently.
Events where the person Did Not Attend (DNA) are excluded.

REVIEWED:
2019-04-23 AK
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_community_visit]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_community_visit];
GO

CREATE VIEW [DL-MAA2016-15].jt_community_visit AS
SELECT [snz_uid]
      ,[moh_nnp_service_date] AS [start_date]
	  ,[moh_nnp_service_date] AS [end_date]
	  ,'community visit' AS [description]
	  ,1 AS [value]
	  ,'moh nnpac' as [source]
FROM [IDI_Clean_20181020].[moh_clean].[nnpac]
WHERE [moh_nnp_event_type_code] = 'CR'
AND [moh_nnp_service_date] IS NOT NULL
AND [moh_nnp_attendence_code] <> 'DNA';
GO

/*
EVENT: Admitted hospital visits
AUTHOR: Simon Anastasiadis
DATE: 2019-01-08
Intended use: Identify health interaction events

Likely to have some overlap with out-patient and ED events as people could be admitted
following such an event.

REVIEWED: 
2019-04-23 AK
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_hospital_admitted]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_hospital_admitted];
GO

CREATE VIEW [DL-MAA2016-15].jt_hospital_admitted AS
SELECT [snz_uid]
      ,[moh_evt_evst_date] AS [start_date]
      ,[moh_evt_even_date] AS [end_date]
	  ,'admitted to hospital' AS [description]
	  ,1 AS [value]
	  ,'moh pfhd' AS [source]
FROM [IDI_Clean_20181020].[moh_clean].[pub_fund_hosp_discharges_event]
WHERE [moh_evt_evst_date] IS NOT NULL
AND [moh_evt_even_date] IS NOT NULL;
GO

/*
EVENT: Pharmacy dispensing of Contraceptives & Antidepressants
AUTHOR: Simon Anastasiadis
DATE: 2019-01-09
Intended use: Identify dispensing events of contraceptives & antidepressants

Only captures dispensing not perscription. People may be perscribed pharmacuticals
but not visit a pharmacy to collect them. In these cases there will be no dispensing.

The full pharmacy table is close to 1 billion records. For the first pass through this
project, this was judged to be too much data to include without some additional sense
of what is of interest. Hence certain types of dispensing were chosen as topical.

REVIEWED: 
2019-04-23 AK
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_pharm_dispensing]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_pharm_dispensing];
GO

CREATE VIEW [DL-MAA2016-15].jt_pharm_dispensing AS
SELECT [snz_uid]
	,[moh_pha_dispensed_date] AS [start_date]
	,[moh_pha_dispensed_date] AS [end_date]
	,'contraceptives dispensing' AS [description]
	,1 AS [value]
	,'moh pharm' AS [source]
FROM [IDI_Clean_20181020].[moh_clean].[pharmaceutical] AS pharm
INNER JOIN [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moh_dim_form_pack_subsidy_code] AS code
ON pharm.moh_pha_dim_form_pack_code = code.[DIM_FORM_PACK_SUBSIDY_KEY]
WHERE [TG_LEVEL1_ID] = 13 -- Genito-Urinary
AND [TG_LEVEL2_ID] IN (1, 8, 9) -- Contraceptives

UNION ALL

SELECT [snz_uid]
	,[moh_pha_dispensed_date] AS [start_date]
	,[moh_pha_dispensed_date] AS [end_date]
	,'antidepressant dispensing' AS [description]
	,1 AS [value]
	,'moh pharm' AS [source]
FROM [IDI_Clean_20181020].[moh_clean].[pharmaceutical] AS pharm
INNER JOIN [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moh_dim_form_pack_subsidy_code] AS code
ON pharm.moh_pha_dim_form_pack_code = code.[DIM_FORM_PACK_SUBSIDY_KEY]
WHERE [TG_LEVEL1_ID] = 22 -- Nervous System
AND [TG_LEVEL2_ID] = 5; -- Antidepressants
GO

/*
EVENT: Industry of Employment
AUTHOR: Simon Anastasiadis
DATE: 2019-01-09
Intended use: Identify industry that a person is employed in

Industry as reported in monthly summary to IRD. Coded according to level 2
of ANZSIC 2006 codes (87 different values).

Note that not perfect identification of role/responsibilities due to lack of
distinction between business industry and personal industry. For example the
manager of a retirement home could have ANZSIC code for management or for 
personal care.

There are two sources from which industry type can be drawn:
PBN = Permanent Business Bumber
ENT = The Entity

REVIEWED:
2019-04-23 AK
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_industry]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_industry];
GO

CREATE VIEW [DL-MAA2016-15].jt_industry AS
SELECT snz_uid
,[ir_ems_return_period_date] AS [start_date]
,[ir_ems_return_period_date] AS [end_date]
,[descriptor_text] AS [description]
,1 AS [value]
,'ird ems anzsic06' AS [source]
FROM (

SELECT [snz_uid]
      ,[ir_ems_return_period_date]
	  ,LEFT(COALESCE([ir_ems_pbn_anzsic06_code], [ir_ems_ent_anzsic06_code]), 1) AS anzsic06
FROM [IDI_Clean_20181020].[ir_clean].[ird_ems]
WHERE [ir_ems_gross_earnings_amt] > 0
AND [ir_ems_income_source_code] = 'W&S'

) k
INNER JOIN [IDI_Metadata].[clean_read_CLASSIFICATIONS].[CEN_ANZSIC06] b
ON k.anzsic06 = b.[cat_code]
WHERE anzsic06 IS NOT NULL;
GO

/*
EVENT: Under management by corrections
AUTHOR: Simon Anastasiadis
DATE: 2019-01-10
Intended use: Identify periods and events of management within the justice system

REVIEWED: 
2019-04-23 AK
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_corrections]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_corrections];
GO

CREATE VIEW [DL-MAA2016-15].jt_corrections AS
SELECT [snz_uid]
      ,[cor_mmp_period_start_date] AS [start_date]
      ,[cor_mmp_period_end_date] AS [end_date]
      ,CASE WHEN [cor_mmp_mmc_code] IN ('COM_DET', 'COM_PROG', 'COM_SERV', 'CW', 'OTH_COM') THEN 'community sentence'
			WHEN [cor_mmp_mmc_code] IN ('PERIODIC', 'PRISON', 'REMAND') THEN 'detained sentence'
			WHEN [cor_mmp_mmc_code] IN ('HD_SENT', 'HD_REL') THEN 'home detention sentence'
			WHEN [cor_mmp_mmc_code] IN ('PAROLE', 'PDC', 'ROC') THEN 'under conditions'
			WHEN [cor_mmp_mmc_code] IN ('ESO', 'INT_SUPER', 'SUPER') THEN 'under supervision'
			END AS [description]
	  ,1 AS [value]
	  ,'corrections' AS [source]
FROM [IDI_Clean_20181020].[cor_clean].[ov_major_mgmt_periods]
WHERE [cor_mmp_mmc_code] NOT IN ('AGED_OUT', 'ALIVE');
GO

/*
EVENT: Court hearing
AUTHOR: Simon Anastasiadis
DATE: 2019-01-10
Intended use: Identify dates of court hearing

Note, only the first and last hearings relating to a spcific charge are recorded.
If a charge has three or more hearings that the hearings other than the first
and last will not appear in the dataset.

REVIEWED: 
2019-04-23 AK
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_court_hearing]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_court_hearing];
GO

CREATE VIEW [DL-MAA2016-15].jt_court_hearing AS
SELECT [snz_uid]
      ,[moj_chg_first_court_hearing_date] AS [start_date]
	  ,[moj_chg_first_court_hearing_date] AS [end_date]
	  ,'court hearing' AS [description]
	  ,1 AS [value]
	  ,'moj charges' AS [source]
FROM [IDI_Clean_20181020].[moj_clean].[charges]
WHERE [moj_chg_first_court_hearing_date] IS NOT NULL

UNION ALL

SELECT [snz_uid]
      ,[moj_chg_last_court_hearing_date] AS [start_date]
	  ,[moj_chg_last_court_hearing_date] AS [end_date]
	  ,'court hearing' AS [description]
	  ,1 AS [value]
	  ,'moj charges' AS [source]
FROM [IDI_Clean_20181020].[moj_clean].[charges]
WHERE [moj_chg_last_court_hearing_date] IS NOT NULL
AND ([moj_chg_first_court_hearing_date] IS NULL
OR [moj_chg_first_court_hearing_date] <> [moj_chg_last_court_hearing_date]);
GO

/*
EVENT: Court proceeding
AUTHOR: Simon Anastasiadis
DATE: 2019-01-10
Intended use: Identify periods where an individual is under stress
due to the laying of court charges that are yet to be resolved.

Requires dates for laid charges and outcome to be recorded. Between
these dates there is an unresolve/outstanding court charge against
the individual.

NOT FOR USE IN V1 and V2 AS INCORRECTLY FILTERED TO "TOP 1000"

REVIEWED: 
2019-04-23 AK
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_court_proceeding]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_court_proceeding];
GO

CREATE VIEW [DL-MAA2016-15].jt_court_proceeding AS
SELECT [snz_uid]
      ,[moj_chg_charge_laid_date] AS [start_date]
      ,[moj_chg_charge_outcome_date] AS [end_date]
	  ,'court proceeding' AS [description]
	  ,1 AS [value]
	  ,'moj charges' AS [source]
FROM [IDI_Clean_20181020].[moj_clean].[charges]
WHERE [moj_chg_charge_laid_date] IS NOT NULL
AND [moj_chg_charge_outcome_date] IS NOT NULL;
GO

/*
EVENT: Exposure to family violence
AUTHOR: Simon Anastasiadis
DATE: 2019-01-10
Intended use: Identify events of exposure to family violence

There are multiple sources of family violence data. These include
victims (RCVS) data from police, offenders (RCOS) data from police,
intake records from CYF, NIA-linked data that combines emergency calls
and police activity notes.
As a first pass we have chosen to use the NIA-linked data. This is
certainly an under-count of incidence of family violence events.
(Consider that the police family violence unit is called out 119k
times per year, but this data contains only 40k records per year.)

Offence codes that correspond to family violence were identified. They are:
1581	COM ASSLT(DOMESTIC)CR ACT(FIREARM)
1582	COM ASSLT(DOMESTIC)CR ACT(OTH WEAP)
1583	COM ASSLT(DOMESTIC)CR ACT(MANUALLY)
1587	COMMON ASSAULT (DOMESTIC) (STABBING/CUTTING WEAPON)
1641	COMMON ASSAULT (DOMESTIC) (FIREARM)
1642	COMMON ASSAULT (DOMESTIC) (OTHER WEAPON)
1643	COMMON ASSAULT (DOMESTIC) (MANUALLY)
1647	COMMON ASSAULT (DOMESTIC) (STABBING/CUTTING WEAPON)
2654	HUSBAND RAPES WIFE
2658	UNLAWFUL SEXUAL CONNECTION WITH SPOUSE
3711	CRUELTY TO/ILLTREAT CHILD (CRIMES ACT)
1D	DOMESTIC DISPUTE

Note that we are limited to exposure to family violence. Distinguishing
between offender and victim (and witness, suspect, informant, etc) was
left for future investigation.

REVIEWED: 
2019-04-23 AK
- Similar to above, is a logic to handle NULL values requeired in dates ?
2019-04-26 SA
- null dates excluded
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_family_violence]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_family_violence];
GO

CREATE VIEW [DL-MAA2016-15].jt_family_violence AS
SELECT [snz_uid]
      ,[nia_links_rec_date] AS [start_date]
	  ,[nia_links_rec_date] AS [end_date]
	  ,'exposed to family violence' AS [description]
	  ,1 AS [value]
	  ,'police nia' AS [source]
--      ,[nia_links_role_type_text]
FROM [IDI_Clean_20181020].[pol_clean].[nia_links]
WHERE [nia_links_latest_inc_off_code] IN ('1581', '1582', '1583', '1587', '1641', '1642', '1643', '1647', '2654', '2658', '3711', '1D')
AND [nia_links_rec_date] IS NOT NULL;
--ORDER BY [snz_pol_offence_uid]
GO

/*
EVENT: Location at time of birth
AUTHOR: Simon Anastasiadis
DATE: 2019-02-19
Intended use: Identify parts of South Auckland

REVIEWED: 
2019-04-23 AK
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_local_board_area]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_local_board_area];
GO

CREATE VIEW [DL-MAA2016-15].jt_local_board_area AS
SELECT a.[snz_uid]
	,DATEFROMPARTS([dia_bir_birth_year_nbr], [dia_bir_birth_month_nbr], 15) AS [start_date]
	,DATEFROMPARTS([dia_bir_birth_year_nbr], [dia_bir_birth_month_nbr], 15) AS [end_date]
	,[CB2017_label] AS [description]
	,[CB2017_code] AS [value]
	,'local board' AS [source]
FROM [IDI_Clean_20181020].[dia_clean].[births] a
INNER JOIN [IDI_Clean_20181020].[data].[address_notification] b
ON a.parent1_snz_uid = b.snz_uid
LEFT JOIN [IDI_Sandpit].[DL-MAA2016-15].[Areas_Table_2017] c
ON b.ant_ta_code = c.TA2017_code
AND b.ant_meshblock_code = c.MB2017_code
WHERE c.CB2017_code IN (7617, 7619, 7618, 7620) -- address is in South Auckland
AND [dia_bir_still_birth_code] IS NULL -- not still born
AND 2005 <= [dia_bir_birth_year_nbr] -- reliable address data exists
AND b.ant_notification_date <= DATEFROMPARTS([dia_bir_birth_year_nbr], [dia_bir_birth_month_nbr], 15)
AND DATEFROMPARTS([dia_bir_birth_year_nbr], [dia_bir_birth_month_nbr], 15) < b.ant_replacement_date -- address is current at time of birth
AND ([dia_bir_parent1_sex_snz_code] = 2
OR [dia_bir_parent1_sex_snz_code] IS NULL
OR [dia_bir_parent1_sex_snz_code] = [dia_bir_parent2_sex_snz_code]) -- parent 1 is female, or no sex recorded, or both parents are same sex

UNION ALL

SELECT a.[snz_uid]
	,DATEFROMPARTS([dia_bir_birth_year_nbr], [dia_bir_birth_month_nbr], 15) AS [start_date]
	,DATEFROMPARTS([dia_bir_birth_year_nbr], [dia_bir_birth_month_nbr], 15) AS [event_date]
	,[CB2017_label] AS [description]
	,[CB2017_code] AS [value]
	,'local board' AS [source]
FROM [IDI_Clean_20181020].[dia_clean].[births] a
INNER JOIN [IDI_Clean_20181020].[data].[address_notification] b
ON a.parent2_snz_uid = b.snz_uid
LEFT JOIN [IDI_Sandpit].[DL-MAA2016-15].[Areas_Table_2017] c
ON b.ant_ta_code = c.TA2017_code
AND b.ant_meshblock_code = c.MB2017_code
WHERE c.CB2017_code IN (7617, 7619, 7618, 7620) -- address is in South Auckland
AND [dia_bir_still_birth_code] IS NULL -- not still born
AND 2005 <= [dia_bir_birth_year_nbr] -- reliable address data exists
AND b.ant_notification_date <= DATEFROMPARTS([dia_bir_birth_year_nbr], [dia_bir_birth_month_nbr], 15)
AND DATEFROMPARTS([dia_bir_birth_year_nbr], [dia_bir_birth_month_nbr], 15) < b.ant_replacement_date -- address is current at time of birth
AND [dia_bir_parent1_sex_snz_code] = 1
AND [dia_bir_parent2_sex_snz_code] = 2; -- parent 2 is female and parent 1 is male
GO

/*
EVENT: A report of concern to CYF that meets Sec 15 criterial
AUTHOR: Simon Anastasiadis
DATE: 2019-04-01
Intended use: Identify concern for children and stress on parents

REVIEWED: 
2019-04-23 AK
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_cyf_intakes]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_cyf_intakes];
GO

CREATE VIEW [DL-MAA2016-15].jt_cyf_intakes AS
SELECT a.[snz_uid]
      ,[cyf_ine_event_from_date_wid_date] AS [start_date]
      ,[cyf_ine_event_from_date_wid_date] AS [end_date]
	  ,'SEC15' AS [description]
	  ,1 AS [value]
	  ,'cyf_intakes' AS [source]
FROM [IDI_Clean_20181020].[cyf_clean].[cyf_intakes_event] a
INNER JOIN [IDI_Clean_20181020].[cyf_clean].[cyf_intakes_details] b
ON a.[snz_composite_event_uid] = b.[snz_composite_event_uid]
WHERE b.[cyf_ind_intake_type_code] = 'SEC15'
GO

/*
EVENT: Being included on an application for social housing
AUTHOR: Simon Anastasiadis
DATE: 2019-04-01
Intended use: Identify social housing applications

REVIEWED:
2019-04-23 AK
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_hnz_apply]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_hnz_apply];
GO

CREATE VIEW [DL-MAA2016-15].jt_hnz_apply AS
SELECT snz_uid
	,[hnz_na_date_of_application_date] AS [start_date]
	,[hnz_na_date_of_application_date] AS [end_date]
	,'apply social housing' AS [description]
	,1 AS [value]
	,'HNZ' as[source]
FROM (

SELECT b.snz_uid
	,a.[hnz_na_date_of_application_date]
FROM [IDI_Clean_20181020].[hnz_clean].[new_applications] a
INNER JOIN [IDI_Clean_20181020].[hnz_clean].[new_applications_household] b
ON a.[snz_msd_application_uid] = b.[snz_msd_application_uid]

UNION ALL

SELECT b.snz_uid
	,a.[hnz_na_date_of_application_date]
FROM [IDI_Clean_20181020].[hnz_clean].[new_applications] a
INNER JOIN [IDI_Clean_20181020].[hnz_clean].[new_applications_household] b
ON a.[snz_application_uid] = b.[snz_application_uid]
WHERE a.[snz_msd_application_uid] IS NULL
OR b.[snz_msd_application_uid] IS NULL

UNION ALL

SELECT b.snz_uid
	,a.[hnz_na_date_of_application_date]
FROM [IDI_Clean_20181020].[hnz_clean].[new_applications] a
INNER JOIN [IDI_Clean_20181020].[hnz_clean].[new_applications_household] b
ON a.[snz_legacy_application_uid] = b.[snz_legacy_application_uid]
WHERE (a.[snz_msd_application_uid] IS NULL
OR b.[snz_msd_application_uid] IS NULL)
AND (a.[snz_application_uid] IS NULL
OR b.[snz_application_uid] IS NULL)

) k
GO

/*
EVENT: Living in social housing
AUTHOR: Simon Anastasiadis
DATE: 2019-04-01
Intended use: Identify social housing tenancy

REVIEWED: 
2019-04-23 AK
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_hnz_tenancy]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_hnz_tenancy];
GO

CREATE VIEW [DL-MAA2016-15].jt_hnz_tenancy AS
SELECT a.[snz_uid]
      ,a.[hnz_ths_snapshot_date] AS [start_date]
	  ,b.[hnz_ths_snapshot_date] AS [end_date]
	  ,'HNZ tenant' AS [description]
	  ,1 AS [value]
	  ,'HNZ' AS [source]
FROM [IDI_Clean_20181020].[hnz_clean].[tenancy_household_snapshot] a
INNER JOIN [IDI_Clean_20181020].[hnz_clean].[tenancy_household_snapshot] b
ON a.snz_uid = b.snz_uid
WHERE DATEDIFF(DAY, a.[hnz_ths_snapshot_date], b.[hnz_ths_snapshot_date]) >= 20
AND DATEDIFF(DAY, a.[hnz_ths_snapshot_date], b.[hnz_ths_snapshot_date]) <= 40
AND (a.[snz_household_uid] = b.[snz_household_uid]
OR a.[snz_legacy_household_uid] = b.[snz_legacy_household_uid])
GO

