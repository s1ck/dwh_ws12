use dwhprak06

/*
Creates an extra column 'surrogate_id' in acm_institution which references to the surrogate insitution.
Creates a view to visually validate the institution's name and the surrogate name.
*/

if OBJECT_ID('dbo.ACM_VALIDATE_SURROGATE_NAMES') IS NOT NULL DROP VIEW [dbo].[ACM_VALIDATE_SURROGATE_NAMES]

if OBJECT_ID('dbo.acm_institution.surrogate_name_id') IS NOT NULL
	ALTER TABLE
		[dbo].[acm_institution] 
	ADD
		[surrogate_name_id] bigint
	CONSTRAINT
		FK_acm_institution_acm_institution
	FOREIGN KEY
		([surrogate_name_id])
	REFERENCES
		[dbo].[acm_institution] ([id]);

UPDATE
	[dbo].[acm_institution]
SET
	[surrogate_name_id] = (
		SELECT
			[grpd].[_key_out]
		FROM
			[dbo].[acm_institution_fuzzy_grouped] as [grpd]
		WHERE
			[acm_institution].[id] = [grpd].[_key_in] 
	)
WHERE EXISTS
	(	SELECT
			[_key_out]
		FROM
			[dbo].[acm_institution] AS [inst]
		JOIN
			[dbo].[acm_institution_fuzzy_grouped] as [grpd]
		ON
			[inst].[id] = [grpd].[_key_in] 
	);
	
GO

-- create the validation view

CREATE VIEW
	[dbo].[ACM_VALIDATE_SURROGATE_NAMES]
AS
	SELECT [inst1].[id]
		,[inst1].[name]
		,[inst2].[id] AS [surrogate_name_id]
		,[inst2].[name] AS [surrogate_name]
	FROM
		[dbo].[acm_institution] AS [inst1]
	JOIN
		[dbo].[acm_institution] AS [inst2]
	ON
		[inst1].[surrogate_name_id] = [inst2].[id]	