use dwhprak06

SELECT
	decade,
	AVG(citings) AS count
FROM (
	SELECT
		pub.year - (pub.year % 10) AS decade,
		num_citings.dblp_pub_id,
		num_citings.citings
	FROM (
		-- joins the
		--   - [dbo].[CUBE_DBLP_GS] containing the numbers of citations
		--     from google scholar 
		-- with the
		--   - [dbo].[CUBE_DBLP_ACM_CITINGS] containing the numbers of
		--     citations from ACM
		-- summing up these values
		SELECT
			--dblp_acm.[dblp_pubId] AS acm_dblp_pub_id
			--,dblp_gs.[dblp_pubId] AS gs_dblp_pub_id
			ISNULL(dblp_acm.[dblp_pubId], dblp_gs.[dblp_pubId]) AS dblp_pub_id
			 ,ISNULL([citingsGS], 0) + ISNULL(citingsACM, 0) AS citings
		FROM
			[dbo].[CUBE_DBLP_GS] dblp_gs
		FULL OUTER JOIN
			[dbo].[CUBE_DBLP_ACM_CITINGS] dblp_acm
		ON
			dblp_acm.dblp_pubId = dblp_gs.dblp_pubId ) AS num_citings
	JOIN
		[dbo].cube_Publication pub
	ON
		num_citings.dblp_pub_id = pub.titleId) AS decaded
GROUP BY
	decade