-- Main query to check full information from the table
SELECT * FROM songs
LIMIT 10
;

SELECT * FROM song_properties
LIMIT 10
;



--Get the list of songs with a popularity rating above 70
--Create a VIEW for future use.
CREATE VIEW high_popularity AS (
SELECT id
	,year
	,artist
	,song
	,genre
	,popularity
	,duration_sec
FROM songs
WHERE popularity >70
)
;



--Checking the averages for the high popularity list
WITH high_cte AS(
SELECT 'high' AS popularity
	,AVG(hg.duration_sec) AS duration
	,AVG(pr.danceability) AS danceability 
	,AVG(pr.energy) AS energy
	,AVG(pr.loudness) AS loudness
	,AVG(pr.speechiness) AS speechiness
	,AVG(pr.valence) AS valence
	,AVG(pr.tempo) AS tempo
FROM high_popularity hg
JOIN song_properties pr
ON hg.id = pr.id
),
--Checking the same metrics for the entire dataset
total_cte AS (
SELECT 'total' AS popularity
	,AVG(sg.duration_sec) AS duration
	,AVG(pr.danceability) AS danceability 
	,AVG(pr.energy) AS energy
	,AVG(pr.loudness) AS loudness
	,AVG(pr.speechiness) AS speechiness
	,AVG(pr.valence) AS valence
	,AVG(pr.tempo) AS tempo
FROM songs sg
JOIN song_properties pr
ON sg.id = pr.id
),
--Checking the same metrics for all data, excluding the high popularity list
low_cte AS (
SELECT 'low' AS popularity
	,AVG(sg.duration_sec) AS duration
	,AVG(pr.danceability) AS danceability 
	,AVG(pr.energy) AS energy
	,AVG(pr.loudness) AS loudness
	,AVG(pr.speechiness) AS speechiness
	,AVG(pr.valence) AS valence
	,AVG(pr.tempo) AS tempo
FROM songs sg
JOIN song_properties pr
ON sg.id = pr.id
LEFT JOIN high_popularity hg
ON hg.id = sg.id
WHERE hg.id IS NULL
)
--Comparing the metrics between high, low, and total popularity
SELECT * FROM high_cte
UNION
SELECT * FROM low_cte
UNION
SELECT * FROM total_cte
;



--The top artists by the number of songs with a high popularity rating
SELECT artist
	,COUNT(DISTINCT song) AS num_of_songs
FROM high_popularity
GROUP BY artist
ORDER BY num_of_songs DESC
;



--Comparing the proportions between the total number of songs by genre and the number of high popularity songs by genre
--Counting the total number of songs by genre
WITH total_genre_cte AS (
SELECT individual_genre
	,COUNT(individual_genre) as num_of_songs_by_genre
FROM
(SELECT unnest(string_to_array(genre, ', ')) AS individual_genre FROM songs) as genres
GROUP BY individual_genre
ORDER BY num_of_songs_by_genre DESC
),
--Counting the number of high popularity songs by genre
popular_genre_cte AS (
SELECT individual_genre
	,COUNT(individual_genre) as num_of_songs_by_genre
FROM
(SELECT unnest(string_to_array(genre, ', ')) AS individual_genre FROM high_popularity) as genres
GROUP BY individual_genre
ORDER BY num_of_songs_by_genre DESC
)
--Combining the counts
SELECT tl.individual_genre
	,tl.num_of_songs_by_genre AS total_genre
	,(tl.num_of_songs_by_genre*100.0/SUM(tl.num_of_songs_by_genre) OVER ()) AS percentage_of_total
	,COALESCE(pl.num_of_songs_by_genre,0) AS popular_genre
	,((COALESCE(pl.num_of_songs_by_genre,0))*100.0/SUM(COALESCE(pl.num_of_songs_by_genre,0)) OVER ()) AS percentage_of_popular
FROM total_genre_cte tl
LEFT JOIN popular_genre_cte pl
ON tl.individual_genre = pl.individual_genre
;



--Counting the number of high popularity songs for each year
SELECT year
	,COUNT(DISTINCT song)
FROM high_popularity
GROUP BY 1
ORDER BY 1
;



--Discovering the top 3 high popularity songs for each year by popularity rating 
WITH rate_per_year AS (
SELECT *
	,DENSE_RANK() OVER(partition by year order by popularity DESC) AS rate
FROM songs
)
				 
SELECT id
	,year
	,artist
	,song
	,genre
	,popularity
FROM rate_per_year
WHERE rate <=3 
ORDER BY year, popularity DESC
;



--Counting the percentage of songs with Explicit marks
SELECT (with_explicit*100)/total AS explicit_percentage
FROM (SELECT SUM(CASE 
				WHEN explicit = TRUE THEN 1
				WHEN explicit = FALSE THEN 0 END) AS with_explicit
			,COUNT(explicit) AS total
		FROM songs) ex
;



--Counting the number of songs per artist
SELECT artist
	,COUNT(DISTINCT song) AS num_of_songs
FROM songs s
GROUP BY 1
ORDER BY 2 DESC
;



--Comparing the number of high popularity songs to the total number of songs for artists with more than 3 songs
SELECT s.artist
	,COUNT(DISTINCT s.song) AS num_of_songs
	,COUNT(DISTINCT hg.song) AS num_of_popular_songs
	,ROUND((COUNT(DISTINCT hg.song))*100.0/COUNT(DISTINCT s.song),2) AS percentage_of_popular
FROM songs s
LEFT JOIN high_popularity  hg
USING(id)
GROUP BY s.artist
HAVING COUNT(DISTINCT s.song)>=3
ORDER BY 2 DESC
;

