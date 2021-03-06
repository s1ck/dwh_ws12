 use [dwhprak06]

IF OBJECT_ID('dbo.build_denormalized_authors_table') IS NOT NULL drop function [dbo].[build_denormalized_authors_table]
IF OBJECT_ID('dbo.get_citingpub_title') IS NOT NULL drop function [dbo].[get_citingpub_title]

IF OBJECT_ID('dbo.acm_self_cited') IS NOT NULL DROP TABLE [dbo].[acm_self_cited]
IF OBJECT_ID('dbo.acm_validate_self_citings') IS NOT NULL DROP VIEW [dbo].[ACM_VALIDATE_SELF_CITINGS]

GO

/*
Takes the 'text' attribute from the acm_cited_by table and extracts the authors.
*/
CREATE FUNCTION
	[dbo].[build_denormalized_authors_table] (
		@text varchar(255)
	)
RETURNS
	@result TABLE (
		[author] varchar(400)
		-- ,[author_pos] int
	)
AS
BEGIN
	DECLARE
		@occurrences int,
		@i int,
		@author varchar(400),
		@author_foo varchar(500)

	-- @text may look sth like this:
	-- Philip S. Yu , Douglas W. Cornell, Buffer management based on return on consumption in a multi-query environment, The VLDB Journal — The International Journal on Very Large Data Bases, v.2 n.1, p.1-38, January 1993
	-- authors are separated from the rest by a comma without any leading whitespaces
	-- two authors are separated from each other by a comma wtith a leading and trailing whitespace
	SET @occurrences = [dbo].[count_occurences](@text, ' , ')
	IF @occurrences > 0
	SET @i = 0;
	BEGIN
		WHILE @i<@occurrences
		BEGIN
			SET @author = [dbo].[get_part](@text, @i+1, ' , ', 1)
			INSERT INTO @result (author)
				SELECT @author
			SET @i = @i + 1
		END
		-- handle last author entry with additional information
		SET @author_foo = [dbo].[get_part](@text, @i+1, ' , ', 1)
		SET @author = [dbo].[get_part](@author_foo, 1, ', ', 1)
		INSERT INTO @result (author)
				SELECT @author
	END
	RETURN
END

GO

CREATE FUNCTION [dbo].[get_citingpub_title](
		@citingpub_str varchar(1000)
	)
RETURNS
	varchar(500)
AS
BEGIN
	DECLARE
		@title varchar(500),
		@auth_occurrences int,
		@part_occurrences int,
		@last_author__title__foo varchar(1000)
	-- input looks sth. like this:
	-- Michael Stonebraker , Greg Kemnitz, The POSTGRES next generation database management system, Communications of the ACM, v.34 n.10, p.78-92, Oct. 1991
	SET @auth_occurrences = [dbo].[count_occurences](@citingpub_str, ' , ') + 1
	IF @auth_occurrences > 0
	BEGIN
		SET @last_author__title__foo = [dbo].[get_part](@citingpub_str, @auth_occurrences, ' , ', 1)
		-- @last_author__title__foo may look like this:
		-- Greg Kemnitz, The POSTGRES next generation database management system, Communications of the ACM, v.34 n.10, p.78-92, Oct. 1991
		SET @part_occurrences = [dbo].[count_occurences](@last_author__title__foo, ', ')
		IF @part_occurrences > 1
		BEGIN
			-- (usually) the second one is the one
			SET @title = [dbo].[get_part](@last_author__title__foo, 2, ', ', 1)
			
			-- special cases:
			-- Chandon Chitale , John Sieg, Jr., Caching transitive closures, Proceedings of the 19th an...
			IF @title = 'Jr.'
			BEGIN
				SET @title = [dbo].[get_part](@last_author__title__foo, 3, ', ', 1)
			END
			
			-- Won't handle titles containing commas here because I do not have a good
			-- heuristic for that. Such thing happen for example in
			-- Roger S. Chin , Samuel T. Chanson, Distributed, object-based programming systems, ACM Computing Surveys (CSUR), v.23 n.1, p.91-124, March 1991
			-- resulting in a title containing just 'Distributed'
		END
	END
	
	RETURN @title
END


GO

/*
Table for all publication tuples which share at least one author
*/

CREATE TABLE [dbo].[acm_self_cited] (
	[publication1_id] bigint,
	[publication2_id] bigint,
	[num_same_authors] int,
	PRIMARY KEY ([publication1_id],[publication2_id])	
)

/*
Validation view
*/

GO

CREATE VIEW
	[dbo].[ACM_VALIDATE_SELF_CITINGS] 
AS SELECT
	pub1.id as publication1_id
	,pub1.title as publication1_title
	,pub2.id as publication2_id
	,pub2.title as publication2_title
	,self_cited.num_same_authors as num_same_authors
	,author1.name as publication1_author
	,author2.name as publication2_author
	,1 as source_id
FROM
	[dbo].[acm_self_cited] self_cited
JOIN
	[dbo].[acm_publication] pub1
ON
	pub1.id = self_cited.publication1_id
JOIN
	[dbo].[acm_publication] pub2
ON
	pub2.id = self_cited.publication2_id
JOIN
	acm_author_publication auth_pub1
ON 
	auth_pub1.publication_id = pub1.id
JOIN
	acm_author author1
ON
	author1.id = auth_pub1.author_id
JOIN
	acm_author_publication auth_pub2
ON
	auth_pub2.publication_id = pub2.id
JOIN
	acm_author author2
ON
	author2.id = auth_pub2.author_id
WHERE
	author1.id = author2.id
UNION
SELECT
	pub1.id as publication1_id
	,pub1.title as publication1_title
	,cited_by.publication2_id as publication2_id
	,dbo.get_citingpub_title(cited_by.text) as publication2_title
	,self_cited.num_same_authors as num_same_authors
	,author1.name as publication1_author
	,result.author as publication2_author
	,2 as source_id
FROM
	[dbo].[acm_self_cited] self_cited
JOIN
	[dbo].[acm_publication] pub1
ON
	pub1.id = self_cited.publication1_id
JOIN
	[dbo].[acm_cited_by] cited_by
ON
	cited_by.publication2_id = self_cited.publication2_id
JOIN
	acm_author_publication auth_pub1
ON 
	auth_pub1.publication_id = pub1.id
JOIN
	acm_author author1
ON
	author1.id = auth_pub1.author_id
OUTER APPLY 
	[dbo].[build_denormalized_authors_table]([cited_by].[text]) as result
WHERE
	cited_by.publication2_id NOT IN (SELECT id FROM acm_publication)
AND
	author1.name = result.author