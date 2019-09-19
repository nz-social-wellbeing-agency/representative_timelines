/******************************************************************************************************************
Description: Establish event/study population view as input to Having a Baby in South Auckland

Input: IDI Clean

Output: Event view in IDI Sandpit
 
Author: Simon Anastasiadis
Reviewer: Akilesh Chokkanathapuram
 
Dependencies:
 
Notes:
1) Currently locked to 2018-10-20 refersh
2) Project prefix = "jt_"

Issues:
 
History (reverse order):
2018-04-24 AK review
2018-12-03 SA v0
******************************************************************************************************************/

Use IDI_UserCode
GO

/* Birth events that occurred by location

We use mother's address at time of birth.

Required columns: event_id (= snz_uid of baby), event_date, location (by address of mother at time of birth)

The address filter for region and meshblock is performed here. 

REVIEWED: 
2019-04-24 AK
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_event_locations]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_event_locations];
GO

CREATE VIEW [DL-MAA2016-15].[jt_event_locations] AS
SELECT a.[snz_uid] AS event_id
	,DATEFROMPARTS([dia_bir_birth_year_nbr], [dia_bir_birth_month_nbr], 15) AS event_date
	,b.ant_notification_date AS address_start_date
	,b.ant_replacement_date AS address_end_date
	,b.snz_idi_address_register_uid AS birth_address
	,[CB2017_label] AS birth_local_area
FROM [IDI_Clean_20181020].[dia_clean].[births] a
INNER JOIN [IDI_Clean_20181020].[data].[address_notification] b
ON a.parent1_snz_uid = b.snz_uid
LEFT JOIN [IDI_Sandpit].[DL-MAA2016-15].[Areas_Table_2017] c
ON b.ant_ta_code = c.TA2017_code
AND b.ant_meshblock_code = c.MB2017_code
--WHERE c.REGC2017_code = 2 --IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 12, 13, 14, 15, 16, 17, 18) -- Auckland Region Code Filter
 WHERE c.CB2017_code IN (7617, 7619, 7618, 7620) -- address is in South Auckland
AND [dia_bir_still_birth_code] IS NULL -- not still born
AND 2005 <= [dia_bir_birth_year_nbr]
AND [dia_bir_birth_year_nbr] <= 2017 -- reliable address data exists
AND b.ant_notification_date <= DATEFROMPARTS([dia_bir_birth_year_nbr], [dia_bir_birth_month_nbr], 15)
AND DATEFROMPARTS([dia_bir_birth_year_nbr], [dia_bir_birth_month_nbr], 15) < b.ant_replacement_date -- address is current at time of birth
AND ([dia_bir_parent1_sex_snz_code] = 2
OR [dia_bir_parent1_sex_snz_code] IS NULL
OR [dia_bir_parent1_sex_snz_code] = [dia_bir_parent2_sex_snz_code]) -- parent 1 is female, or no sex recorded, or both parents are same sex

UNION ALL

SELECT a.[snz_uid] AS event_id
	,DATEFROMPARTS([dia_bir_birth_year_nbr], [dia_bir_birth_month_nbr], 15) AS event_date
	,b.ant_notification_date AS address_start_date
	,b.ant_replacement_date AS address_end_date
	,b.snz_idi_address_register_uid AS birth_address
	,[CB2017_label] AS birth_local_area
FROM [IDI_Clean_20181020].[dia_clean].[births] a
INNER JOIN [IDI_Clean_20181020].[data].[address_notification] b
ON a.parent2_snz_uid = b.snz_uid
LEFT JOIN [IDI_Sandpit].[DL-MAA2016-15].[Areas_Table_2017] c
ON b.ant_ta_code = c.TA2017_code
AND b.ant_meshblock_code = c.MB2017_code
-- WHERE c.REGC2017_code = 2 -- Auckland Region Code Filter
WHERE c.CB2017_code IN (7617, 7619, 7618, 7620) -- address is in South Auckland
AND [dia_bir_still_birth_code] IS NULL -- not still born
AND 2005 <= [dia_bir_birth_year_nbr]
AND [dia_bir_birth_year_nbr] <= 2017 -- reliable address data exists
AND b.ant_notification_date <= DATEFROMPARTS([dia_bir_birth_year_nbr], [dia_bir_birth_month_nbr], 15)
AND DATEFROMPARTS([dia_bir_birth_year_nbr], [dia_bir_birth_month_nbr], 15) < b.ant_replacement_date -- address is current at time of birth
AND [dia_bir_parent1_sex_snz_code] = 1
AND [dia_bir_parent2_sex_snz_code] = 2; -- parent 2 is female and parent 1 is male
GO


/* Birth events that occurred by location - Auckland Filter Applied

We use mother's address at time of birth.

Required columns: event_id (= snz_uid of baby), event_date, location (by address of mother at time of birth)

Auckland is REGC2017_code = 2

REVIEWED: 
2019-04-24 AK
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_event_locations_AKL]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_event_locations_AKL];
GO

CREATE VIEW [DL-MAA2016-15].[jt_event_locations_AKL] AS
SELECT a.[snz_uid] AS event_id
	,DATEFROMPARTS([dia_bir_birth_year_nbr], [dia_bir_birth_month_nbr], 15) AS event_date
	,b.ant_notification_date AS address_start_date
	,b.ant_replacement_date AS address_end_date
	,b.snz_idi_address_register_uid AS birth_address
	,[CB2017_label] AS birth_local_area
FROM [IDI_Clean_20181020].[dia_clean].[births] a
INNER JOIN [IDI_Clean_20181020].[data].[address_notification] b
ON a.parent1_snz_uid = b.snz_uid
LEFT JOIN [IDI_Sandpit].[DL-MAA2016-15].[Areas_Table_2017] c
ON b.ant_ta_code = c.TA2017_code
AND b.ant_meshblock_code = c.MB2017_code
WHERE c.REGC2017_code = 2 --IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 12, 13, 14, 15, 16, 17, 18) -- Auckland Region Code Filter
-- WHERE c.CB2017_code IN (7617, 7619, 7618, 7620) -- address is in South Auckland
AND [dia_bir_still_birth_code] IS NULL -- not still born
AND 2005 <= [dia_bir_birth_year_nbr]
AND [dia_bir_birth_year_nbr] <= 2017 -- reliable address data exists
AND b.ant_notification_date <= DATEFROMPARTS([dia_bir_birth_year_nbr], [dia_bir_birth_month_nbr], 15)
AND DATEFROMPARTS([dia_bir_birth_year_nbr], [dia_bir_birth_month_nbr], 15) < b.ant_replacement_date -- address is current at time of birth
AND ([dia_bir_parent1_sex_snz_code] = 2
OR [dia_bir_parent1_sex_snz_code] IS NULL
OR [dia_bir_parent1_sex_snz_code] = [dia_bir_parent2_sex_snz_code]) -- parent 1 is female, or no sex recorded, or both parents are same sex

UNION ALL

SELECT a.[snz_uid] AS event_id
	,DATEFROMPARTS([dia_bir_birth_year_nbr], [dia_bir_birth_month_nbr], 15) AS event_date
	,b.ant_notification_date AS address_start_date
	,b.ant_replacement_date AS address_end_date
	,b.snz_idi_address_register_uid AS birth_address
	,[CB2017_label] AS birth_local_area
FROM [IDI_Clean_20181020].[dia_clean].[births] a
INNER JOIN [IDI_Clean_20181020].[data].[address_notification] b
ON a.parent2_snz_uid = b.snz_uid
LEFT JOIN [IDI_Sandpit].[DL-MAA2016-15].[Areas_Table_2017] c
ON b.ant_ta_code = c.TA2017_code
AND b.ant_meshblock_code = c.MB2017_code
WHERE c.REGC2017_code = 2 -- Auckland Region Code Filter
-- WHERE c.CB2017_code IN (7617, 7619, 7618, 7620) -- address is in South Auckland
AND [dia_bir_still_birth_code] IS NULL -- not still born
AND 2005 <= [dia_bir_birth_year_nbr]
AND [dia_bir_birth_year_nbr] <= 2017 -- reliable address data exists
AND b.ant_notification_date <= DATEFROMPARTS([dia_bir_birth_year_nbr], [dia_bir_birth_month_nbr], 15)
AND DATEFROMPARTS([dia_bir_birth_year_nbr], [dia_bir_birth_month_nbr], 15) < b.ant_replacement_date -- address is current at time of birth
AND [dia_bir_parent1_sex_snz_code] = 1
AND [dia_bir_parent2_sex_snz_code] = 2; -- parent 2 is female and parent 1 is male
GO

/* Birth events that occurred by location - NZ Filter Applied i.e. No Filter

We use mother's address at time of birth.

Required columns: event_id (= snz_uid of baby), event_date, location (by address of mother at time of birth)

REGC2017_code = ALL

REVIEWED: 
2019-04-24 AK
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_event_locations_NZ]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_event_locations_NZ];
GO

CREATE VIEW [DL-MAA2016-15].[jt_event_locations_NZ] AS
SELECT a.[snz_uid] AS event_id
	,DATEFROMPARTS([dia_bir_birth_year_nbr], [dia_bir_birth_month_nbr], 15) AS event_date
	,b.ant_notification_date AS address_start_date
	,b.ant_replacement_date AS address_end_date
	,b.snz_idi_address_register_uid AS birth_address
	,[CB2017_label] AS birth_local_area
FROM [IDI_Clean_20181020].[dia_clean].[births] a
INNER JOIN [IDI_Clean_20181020].[data].[address_notification] b
ON a.parent1_snz_uid = b.snz_uid
LEFT JOIN [IDI_Sandpit].[DL-MAA2016-15].[Areas_Table_2017] c
ON b.ant_ta_code = c.TA2017_code
AND b.ant_meshblock_code = c.MB2017_code
WHERE c.REGC2017_code IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 12, 13, 14, 15, 16, 17, 18) -- NZ Region Code Filter
-- WHERE c.CB2017_code IN (7617, 7619, 7618, 7620) -- address is in South Auckland
AND [dia_bir_still_birth_code] IS NULL -- not still born
AND 2005 <= [dia_bir_birth_year_nbr]
AND [dia_bir_birth_year_nbr] <= 2017 -- reliable address data exists
AND b.ant_notification_date <= DATEFROMPARTS([dia_bir_birth_year_nbr], [dia_bir_birth_month_nbr], 15)
AND DATEFROMPARTS([dia_bir_birth_year_nbr], [dia_bir_birth_month_nbr], 15) < b.ant_replacement_date -- address is current at time of birth
AND ([dia_bir_parent1_sex_snz_code] = 2
OR [dia_bir_parent1_sex_snz_code] IS NULL
OR [dia_bir_parent1_sex_snz_code] = [dia_bir_parent2_sex_snz_code]) -- parent 1 is female, or no sex recorded, or both parents are same sex

UNION ALL

SELECT a.[snz_uid] AS event_id
	,DATEFROMPARTS([dia_bir_birth_year_nbr], [dia_bir_birth_month_nbr], 15) AS event_date
	,b.ant_notification_date AS address_start_date
	,b.ant_replacement_date AS address_end_date
	,b.snz_idi_address_register_uid AS birth_address
	,[CB2017_label] AS birth_local_area
FROM [IDI_Clean_20181020].[dia_clean].[births] a
INNER JOIN [IDI_Clean_20181020].[data].[address_notification] b
ON a.parent2_snz_uid = b.snz_uid
LEFT JOIN [IDI_Sandpit].[DL-MAA2016-15].[Areas_Table_2017] c
ON b.ant_ta_code = c.TA2017_code
AND b.ant_meshblock_code = c.MB2017_code
WHERE c.REGC2017_code IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 12, 13, 14, 15, 16, 17, 18) -- NZ Region Code Filter
-- WHERE c.CB2017_code IN (7617, 7619, 7618, 7620) -- address is in South Auckland
AND [dia_bir_still_birth_code] IS NULL -- not still born
AND 2005 <= [dia_bir_birth_year_nbr]
AND [dia_bir_birth_year_nbr] <= 2017 -- reliable address data exists
AND b.ant_notification_date <= DATEFROMPARTS([dia_bir_birth_year_nbr], [dia_bir_birth_month_nbr], 15)
AND DATEFROMPARTS([dia_bir_birth_year_nbr], [dia_bir_birth_month_nbr], 15) < b.ant_replacement_date -- address is current at time of birth
AND [dia_bir_parent1_sex_snz_code] = 1
AND [dia_bir_parent2_sex_snz_code] = 2; -- parent 2 is female and parent 1 is male
GO

/* Event and roles associated with it 

Required columns: snz_uid, role, event_ID (= snz_uid of baby)

REVIEWED: 
2019-04-24 AK
Updated Year Comparison to represent 'Variable >= Value'
*/
IF OBJECT_ID('[DL-MAA2016-15].[jt_event_roles]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[jt_event_roles];
GO

CREATE VIEW [DL-MAA2016-15].[jt_event_roles] AS

/* Baby */
SELECT [snz_uid]
		,'baby' AS [role]
		,[snz_uid] AS [event_id]
FROM [IDI_Clean_20181020].[dia_clean].[births]
WHERE dia_bir_birth_year_nbr >= 1990 -- birth post 1990
AND [dia_bir_still_birth_code] IS NULL -- not still born

UNION ALL

/* Mother */
SELECT [parent1_snz_uid]
		,'mother' AS [role]
		,[snz_uid] AS [event_ID]
FROM [IDI_Clean_20181020].[dia_clean].[births]
WHERE dia_bir_birth_year_nbr >= 1990 -- birth post 1990
AND [dia_bir_still_birth_code] IS NULL -- not still born
AND [parent1_snz_uid] IS NOT NULL -- parent ID exists
AND ([dia_bir_parent1_sex_snz_code] = 2
OR [dia_bir_parent1_sex_snz_code] IS NULL
OR [dia_bir_parent1_sex_snz_code] = [dia_bir_parent2_sex_snz_code]) -- parent 1 is female, or no sex recorded, or both parents are same sex

UNION ALL

SELECT [parent2_snz_uid]
		,'mother' AS [role]
		,[snz_uid] AS [event_ID]
FROM [IDI_Clean_20181020].[dia_clean].[births]
WHERE dia_bir_birth_year_nbr >= 1990 -- birth post 1990
AND [dia_bir_still_birth_code] IS NULL -- not still born
AND [parent2_snz_uid] IS NOT NULL -- parent ID exists
AND [dia_bir_parent1_sex_snz_code] = 1
AND [dia_bir_parent2_sex_snz_code] = 2 -- parent 2 is female and parent 1 is male

UNION ALL

/* Father */
SELECT [parent2_snz_uid]
		,'father' AS [role]
		,[snz_uid] AS [event_ID]
FROM [IDI_Clean_20181020].[dia_clean].[births]
WHERE dia_bir_birth_year_nbr >= 1990 -- birth post 1990
AND [dia_bir_still_birth_code] IS NULL -- not still born
AND [parent2_snz_uid] IS NOT NULL -- parent ID exists
AND ([dia_bir_parent2_sex_snz_code] = 1
OR [dia_bir_parent2_sex_snz_code] IS NULL
OR [dia_bir_parent1_sex_snz_code] = [dia_bir_parent2_sex_snz_code]) -- parent 2 is male, or no sex recorded, or both parents are same sex

UNION ALL

SELECT [parent1_snz_uid]
		,'father' AS [role]
		,[snz_uid] AS [event_ID]
FROM [IDI_Clean_20181020].[dia_clean].[births]
WHERE dia_bir_birth_year_nbr >= 1990 -- birth post 1990
AND [dia_bir_still_birth_code] IS NULL -- not still born
AND [parent1_snz_uid] IS NOT NULL -- parent ID exists
AND [dia_bir_parent1_sex_snz_code] = 1
AND [dia_bir_parent2_sex_snz_code] = 2 -- parent 1 is male and parent 2 is female

UNION ALL

/* Siblings - full */
SELECT sib.snz_uid
		,'full sibling' AS [role]
		,baby.snz_uid AS event_id
FROM [IDI_Clean_20181020].[dia_clean].[births] baby
INNER JOIN [IDI_Clean_20181020].[dia_clean].[births] sib
ON (baby.parent1_snz_uid = sib.parent1_snz_uid AND baby.parent2_snz_uid = sib.parent2_snz_uid) -- same parents
WHERE baby.dia_bir_birth_year_nbr >= 1990  -- birth post 1990
AND baby.[dia_bir_still_birth_code] IS NULL -- baby not still born
AND sib.[dia_bir_still_birth_code] IS NULL -- sibling not still born
AND baby.parent1_snz_uid IS NOT NULL
AND baby.parent2_snz_uid IS NOT NULL -- baby has 2 birth parents
AND (sib.dia_bir_birth_year_nbr < baby.dia_bir_birth_year_nbr
OR (sib.dia_bir_birth_year_nbr = baby.dia_bir_birth_year_nbr
AND sib.dia_bir_birth_month_nbr < baby.dia_bir_birth_month_nbr)) -- sibling is born before baby

UNION ALL

SELECT sib.snz_uid
		,'full sibling' AS [role]
		,baby.snz_uid AS event_id
FROM [IDI_Clean_20181020].[dia_clean].[births] baby
INNER JOIN [IDI_Clean_20181020].[dia_clean].[births] sib
ON (baby.parent2_snz_uid = sib.parent1_snz_uid AND baby.parent1_snz_uid = sib.parent2_snz_uid) -- same parents, reversed order
WHERE baby.dia_bir_birth_year_nbr >= 1990 -- birth post 1990
AND baby.[dia_bir_still_birth_code] IS NULL -- baby not still born
AND sib.[dia_bir_still_birth_code] IS NULL -- sibling not still born
AND baby.parent1_snz_uid IS NOT NULL
AND baby.parent2_snz_uid IS NOT NULL -- baby has 2 birth parents
AND (sib.dia_bir_birth_year_nbr < baby.dia_bir_birth_year_nbr
OR (sib.dia_bir_birth_year_nbr = baby.dia_bir_birth_year_nbr
AND sib.dia_bir_birth_month_nbr < baby.dia_bir_birth_month_nbr)) -- sibling is born before baby

UNION ALL

/* Siblings - half */
SELECT sib.snz_uid
		,'half sibling' AS [role]
		,baby.snz_uid AS event_id
FROM [IDI_Clean_20181020].[dia_clean].[births] baby
INNER JOIN [IDI_Clean_20181020].[dia_clean].[births] sib
ON baby.parent1_snz_uid = sib.parent1_snz_uid -- baby and sibling have same parent1
WHERE baby.dia_bir_birth_year_nbr >= 1990 -- birth post 1990
AND baby.[dia_bir_still_birth_code] IS NULL -- baby not still born
AND sib.[dia_bir_still_birth_code] IS NULL -- sibling not still born
AND baby.parent1_snz_uid IS NOT NULL -- baby has birth parent1
AND (baby.parent2_snz_uid <> sib.parent2_snz_uid
	OR baby.parent2_snz_uid IS NULL
	OR sib.parent2_snz_uid IS NULL) -- baby and sibling have different parent2, or no parent2
AND (sib.dia_bir_birth_year_nbr < baby.dia_bir_birth_year_nbr
	OR (sib.dia_bir_birth_year_nbr = baby.dia_bir_birth_year_nbr
		AND sib.dia_bir_birth_month_nbr < baby.dia_bir_birth_month_nbr)) -- sibling is born before baby

UNION ALL

SELECT sib.snz_uid
		,'half sibling' AS [role]
		,baby.snz_uid AS event_id
FROM [IDI_Clean_20181020].[dia_clean].[births] baby
INNER JOIN [IDI_Clean_20181020].[dia_clean].[births] sib
ON baby.parent1_snz_uid = sib.parent2_snz_uid -- baby parent1 = sibling parent2
WHERE baby.dia_bir_birth_year_nbr >= 1990 -- birth post 1990
AND baby.[dia_bir_still_birth_code] IS NULL -- baby not still born
AND sib.[dia_bir_still_birth_code] IS NULL -- sibling not still born
AND baby.parent1_snz_uid IS NOT NULL -- baby has birth parent1
AND (baby.parent2_snz_uid <> sib.parent1_snz_uid
	OR baby.parent2_snz_uid IS NULL
	OR sib.parent1_snz_uid IS NULL) -- baby and sibling other parent is different, or no other parent
AND (sib.dia_bir_birth_year_nbr < baby.dia_bir_birth_year_nbr
	OR (sib.dia_bir_birth_year_nbr = baby.dia_bir_birth_year_nbr
		AND sib.dia_bir_birth_month_nbr < baby.dia_bir_birth_month_nbr)) -- sibling is born before baby

UNION ALL

SELECT sib.snz_uid
		,'half sibling' AS [role]
		,baby.snz_uid AS event_id
FROM [IDI_Clean_20181020].[dia_clean].[births] baby
INNER JOIN [IDI_Clean_20181020].[dia_clean].[births] sib
ON baby.parent2_snz_uid = sib.parent2_snz_uid -- baby and sibling have same parent2
WHERE baby.dia_bir_birth_year_nbr >= 1990 -- birth post 1990
AND baby.[dia_bir_still_birth_code] IS NULL -- baby not still born
AND sib.[dia_bir_still_birth_code] IS NULL -- sibling not still born
AND baby.parent2_snz_uid IS NOT NULL -- baby has birth parent2
AND (baby.parent1_snz_uid <> sib.parent1_snz_uid
	OR baby.parent1_snz_uid IS NULL
	OR sib.parent1_snz_uid IS NULL) -- baby and sibling have different parent1, or no parent 1
AND (sib.dia_bir_birth_year_nbr < baby.dia_bir_birth_year_nbr
OR (sib.dia_bir_birth_year_nbr = baby.dia_bir_birth_year_nbr
AND sib.dia_bir_birth_month_nbr < baby.dia_bir_birth_month_nbr)) -- sibling is born before baby

UNION ALL

SELECT sib.snz_uid
		,'half sibling' AS [role]
		,baby.snz_uid AS event_id
FROM [IDI_Clean_20181020].[dia_clean].[births] baby
INNER JOIN [IDI_Clean_20181020].[dia_clean].[births] sib
ON baby.parent2_snz_uid = sib.parent1_snz_uid -- baby parent2 = sibling parent1
WHERE baby.dia_bir_birth_year_nbr >= 1990 -- birth post 1990
AND baby.[dia_bir_still_birth_code] IS NULL -- baby not still born
AND sib.[dia_bir_still_birth_code] IS NULL -- sibling not still born
AND baby.parent2_snz_uid IS NOT NULL -- baby has birth parent2
AND (baby.parent1_snz_uid <> sib.parent2_snz_uid
	OR baby.parent1_snz_uid IS NULL
	OR sib.parent2_snz_uid IS NULL) -- baby and sibling other parent is different, or no other parent
AND (sib.dia_bir_birth_year_nbr < baby.dia_bir_birth_year_nbr
OR (sib.dia_bir_birth_year_nbr = baby.dia_bir_birth_year_nbr
AND sib.dia_bir_birth_month_nbr < baby.dia_bir_birth_month_nbr)) -- sibling is born before baby
GO


