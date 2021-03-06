USE dwhprak06

IF OBJECT_ID('dbo.mine_AssoRegeln') IS NOT NULL DROP TABLE [dbo].[mine_AssoRegeln]

CREATE TABLE [dbo].[mine_AssoRegeln] (
		AuthorId BIGINT NOT NULL
		,VenueSeriesId BIGINT NOT NULL
		,VenueSeriesName VARCHAR(500)
	)

INSERT INTO [dbo].[mine_AssoRegeln] (
		AuthorId
		,VenueSeriesId
		,VenueSeriesName
	)
SELECT DISTINCT
	auth.[id] AS AuthorId
    ,venser.[id] AS VenueSeriesId
    ,venser.[name] AS VenueSeriesName
FROM
	[dbo].[dblp_author] auth
JOIN
	[dbo].[dblp_author_publication] auth_pub
ON
	auth.id = auth_pub.author_id 
JOIN
	[dbo].[dblp_venue_publication] pub_ven
ON
	auth_pub.publication_id = pub_ven.publication_id
JOIN
	[dbo].[dblp_venue] ven
ON
	pub_ven.venue_id = ven.id
JOIN
	[dbo].[dblp_venue_series] venser
ON
	ven.venue_series_id = venser.id
ORDER BY
	auth.[id]