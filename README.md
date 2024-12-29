# Spotify_project
[Spotify_logo](https://github.com/Andrii-Klipailo/Spotify_project/blob/main/spotify_logo.jpg)
## Overview
Analyzing the most popular songs on Spotify in order to find the main patterns in them.
This dataset contains audio statistics of the top 2000 tracks on Spotify from 2000 to 2019.
The dataset is split into 2 table:
 - Songs 
 - Song_properties


### Analysis of the dataset using SQL
```SQL
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
```
### Analysis of average characteristics for songs with high, low, and overall popularity

```SQL
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
```
### Top artists by the number of songs with high popularity rating

```SQL
--The top artists by the number of songs with a high popularity rating
SELECT artist
	,COUNT(DISTINCT song) AS num_of_songs
FROM high_popularity
GROUP BY artist
ORDER BY num_of_songs DESC
;
```

### Comparing the proportions between the total number of songs by genre and the number of high popularity songs by genre

```SQL
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
```

### Number of high popularity songs for each year

```SQL
--Counting the number of high popularity songs for each year
SELECT year
	,COUNT(DISTINCT song)
FROM high_popularity
GROUP BY 1
ORDER BY 1
;
```

### Top 3 high popularity songs for each year by popularity rating"

```SQL
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
```

### Percentage of songs marked as Explicit in the dataset

```SQL
--Calculating the percentage of songs with Explicit marks
SELECT (with_explicit*100)/total AS explicit_percentage
FROM (SELECT SUM(CASE 
				WHEN explicit = TRUE THEN 1
				WHEN explicit = FALSE THEN 0 END) AS with_explicit
			,COUNT(explicit) AS total
		FROM songs) ex
;
```

### Number of songs per artist in the dataset

```SQL
--Counting the number of songs per artist
SELECT artist
	,COUNT(DISTINCT song) AS num_of_songs
FROM songs s
GROUP BY 1
ORDER BY 2 DESC
;
```

### Comparison of high popularity songs and total songs for artists with more than 3 songs

```SQL 
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
```



## Findings and Conclusion

The analysis of the top 2000 tracks on Spotify reveals key insights:
High Popularity Characteristics: Popular songs tend to have higher energy, danceability, and tempo compared to less popular tracks.
Genre Preferences: Genres like pop and hip-hop dominate high popularity songs, reflecting global music trends.
Top Artists: A small group of artists contribute significantly to popular tracks, showcasing the importance of consistency.
Explicit Content: Many popular songs feature explicit content, reflecting broader trends in mainstream music.
Yearly Trends: The number of high popularity songs varies over time, indicating shifts in musical preferences.


In conclusion, specific characteristics like genre, energy, and explicit content play a significant role in a song's popularity, with some artists and genres consistently performing well.















## Additional information


### Сontents of the tables

#### Songs table:

•	id: unique id
•	artist: Name of the Artist.
•	song: Name of the Track.
•	duration_sc: Duration of the track in seconds.
•	explicit: The lyrics or content of a song or a music video contain one or more of the criteria which could be considered offensive or unsuitable for children.
•	year: Release Year of the track.
•	popularity: The higher the value the more popular the song is.
•	danceability: Danceability describes how suitable a track is for dancing based on a combination of musical elements including tempo, rhythm stability, beat strength, and overall regularity. A value of 0.0 is least danceable and 1.0 is most danceable.
•	genre: Genre of the track.

#### Song_properties table:

•	id: unique id
•	energy: Energy is a measure from 0.0 to 1.0 and represents a perceptual measure of intensity and activity.
•	key: The key the track is in. Integers map to pitches using standard Pitch Class notation. E.g. 0 = C, 1 = C♯/D♭, 2 = D, and so on. If no key was detected, the value is -1.
•	loudness: The overall loudness of a track in decibels (dB). Loudness values are averaged across the entire track and are useful for comparing relative loudness of tracks. Loudness is the quality of a sound that is the primary psychological correlate of physical strength (amplitude). Values typically range between -60 and 0 db.
•	mode: Mode indicates the modality (major or minor) of a track, the type of scale from which its melodic content is derived. Major is represented by 1 and minor is 0.
•	speechiness: Speechiness detects the presence of spoken words in a track. The more exclusively speech-like the recording (e.g. talk show, audio book, poetry), the closer to 1.0 the attribute value. Values above 0.66 describe tracks that are probably made entirely of spoken words. Values between 0.33 and 0.66 describe tracks that may contain both music and speech, either in sections or layered, including such cases as rap music. Values below 0.33 most likely represent music and other non-speech-like tracks.
•	acousticness: A confidence measure from 0.0 to 1.0 of whether the track is acoustic. 1.0 represents high confidence the track is acoustic.
•	instrumentalness: Predicts whether a track contains no vocals. "Ooh" and "aah" sounds are treated as instrumental in this context. Rap or spoken word tracks are clearly "vocal". The closer the instrumentalness value is to 1.0, the greater likelihood the track contains no vocal content. Values above 0.5 are intended to represent instrumental tracks, but confidence is higher as the value approaches 1.0.
•	liveness: Detects the presence of an audience in the recording. Higher liveness values represent an increased probability that the track was performed live. A value above 0.8 provides strong likelihood that the track is live.
•	valence: A measure from 0.0 to 1.0 describing the musical positiveness conveyed by a track. Tracks with high valence sound more positive (e.g. happy, cheerful, euphoric), while tracks with low valence sound more negative (e.g. sad, depressed, angry).
•	tempo: The overall estimated tempo of a track in beats per minute (BPM). In musical terminology, tempo is the speed or pace of a given piece and derives directly from the average beat duration.
