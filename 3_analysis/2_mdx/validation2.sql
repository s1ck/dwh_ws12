use [dwhprak06]

/****** Skript für SelectTopNRows-Befehl aus SSMS  ******/
SELECT
	description,
	decade,
	AVG(citings) AS avg_citings
FROM (
	SELECT pub.[id]
		  ,[year] - ([year] % 10) as decade
		  ,venser.description
		  ,[citingsGS] + [citingsACM] AS citings
	  FROM
		[dbo].[cube_Publication] pub
	  JOIN
		[dbo].[cube_VenueSeries] venser
	  ON
		pub.venueSeriesId = venser.id
	) AS joined
GROUP BY
	description,
	decade
ORDER BY
	description, decade