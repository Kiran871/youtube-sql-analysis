-- Common Queries
-- Q1: What are the top 10 most viewed videos in the trending list?
SELECT title, channel_title, views
FROM youtube_india_clean
ORDER BY views DESC
LIMIT 10;
 
-- Q2: Which channel has the highest total views across all its trending videos?
SELECT channel_title, SUM(views) AS total_views
FROM youtube_india_clean
GROUP BY channel_title
ORDER BY total_views DESC
LIMIT 10;

-- Q3: Which videos appeared most frequently in the trending list (i.e., across multiple days)?
SELECT title, COUNT(*) AS days_trended
FROM youtube_india_clean
GROUP BY title
ORDER BY days_trended DESC
LIMIT 10;

-- Q4: What is the average number of days it took for a video to trend after being published?
SELECT 
    ROUND(AVG(JULIANDAY(trending_date) - JULIANDAY(publish_time)), 2) AS avg_days_to_trend
FROM youtube_india_clean
WHERE JULIANDAY(trending_date) > JULIANDAY(publish_time);

-- Q5: What are the top 10 most liked videos in the dataset?
SELECT title, channel_title, likes
FROM youtube_india_clean
ORDER BY likes DESC
LIMIT 10;

-- Q6: Which videos have the best like-to-dislike ratio (minimum 10000 dislikes)?
SELECT title, channel_title, 
       ROUND(CAST(likes AS FLOAT)/NULLIF(dislikes, 0), 2) AS like_dislike_ratio
FROM youtube_india_clean
WHERE dislikes >= 10000
ORDER BY like_dislike_ratio DESC
LIMIT 10;

-- Q7: How many videos trended each day?
SELECT trending_date, COUNT(*) AS videos_trending
FROM youtube_india_clean
GROUP BY trending_date
ORDER BY trending_date;

-- Q8: Which channels have the most number of unique trending videos?
SELECT channel_title, COUNT(DISTINCT title) AS total_trending_videos
FROM youtube_india_clean
GROUP BY channel_title
ORDER BY total_trending_videos DESC
LIMIT 10;

-- Q9: What is the total view count per category?
-- Note: You'll need to join this with a category mapping table (we can add that if you want).
SELECT category_id, SUM(views) AS total_views
FROM youtube_india_clean
GROUP BY category_id
ORDER BY total_views DESC;

-- Q10: Identify videos with more dislikes than likes (controversial content).
SELECT title, channel_title, likes, dislikes
FROM youtube_india_clean
WHERE dislikes > likes
ORDER BY dislikes DESC;

-- Complex Queries
-- Q1: Which channels have more than 5 videos trending and the highest average views per video?
SELECT channel_title, COUNT(*) AS total_trending_videos, AVG(views) AS avg_views
FROM youtube_india_clean
GROUP BY channel_title
HAVING COUNT(*) > 5
ORDER BY avg_views DESC
LIMIT 10;

-- Q2: Which category (by category_id) got the most likes overall?
SELECT category_id, SUM(likes) AS total_likes
FROM youtube_india_clean
GROUP BY category_id
ORDER BY total_likes DESC;

-- Q3: What is the average like-to-dislike ratio for each category?
SELECT category_id,
       ROUND(AVG(CASE WHEN dislikes != 0 THEN CAST(likes AS FLOAT)/dislikes ELSE NULL END), 2) AS avg_like_dislike_ratio
FROM youtube_india_clean
GROUP BY category_id
ORDER BY avg_like_dislike_ratio DESC;

-- Q4: Which videos had a sudden spike in likes (>500k likes but <1M views)?
SELECT title, channel_title, views, likes
FROM youtube_india_clean
WHERE likes > 500000 AND views < 1000000
ORDER BY likes DESC;

-- Q5: Most frequent trending date per channel (mode of date per channel)
SELECT channel_title, trending_date, COUNT(*) as trend_count
FROM youtube_india_clean
GROUP BY channel_title, trending_date
HAVING trend_count = (
    SELECT MAX(cnt)
    FROM (
        SELECT channel_title AS ch, trending_date AS td, COUNT(*) AS cnt
        FROM youtube_india_clean
        GROUP BY ch, td
        HAVING ch = youtube_india_clean.channel_title
    )
)
ORDER BY trend_count DESC;

-- Q6: Which video titles have trended on multiple days and their total days in trending?
SELECT title, COUNT(DISTINCT trending_date) AS days_trending
FROM youtube_india_clean
GROUP BY title
HAVING days_trending > 1
ORDER BY days_trending DESC;

-- Q7: What’s the top 5 channels with highest total engagement (likes + dislikes + comments)?
SELECT channel_title,
       SUM(likes + dislikes + comment_count) AS total_engagement
FROM youtube_india_clean
GROUP BY channel_title
ORDER BY total_engagement DESC
LIMIT 5;

-- Q8: Use a CTE to find the video with the highest engagement ratio (engagement/views)
WITH video_engagement AS (
    SELECT title, views, likes + dislikes + comment_count AS engagement
    FROM youtube_india_clean
    WHERE views > 0
)
SELECT title, ROUND(engagement*1.0 / views, 2) AS engagement_ratio
FROM video_engagement
ORDER BY engagement_ratio DESC
LIMIT 10;

-- Q9: Use window functions to rank videos by views per channel
SELECT title, channel_title, views,
       RANK() OVER (PARTITION BY channel_title ORDER BY views DESC) AS view_rank
FROM youtube_india_clean
ORDER BY channel_title, view_rank;

-- Q10: Top 3 most liked videos for each category_id using window functions
SELECT *
FROM (
    SELECT title, category_id, likes,
           RANK() OVER (PARTITION BY category_id ORDER BY likes DESC) AS like_rank
    FROM youtube_india_clean
) AS ranked
WHERE like_rank <= 3;

-- Q11: Channel with the highest average daily engagement (likes + comments / days trending)
WITH daily_engagement AS (
    SELECT channel_title, title, COUNT(DISTINCT trending_date) AS trend_days,
           SUM(likes + comment_count) AS total_engagement
    FROM youtube_india_clean
    GROUP BY channel_title, title
)
SELECT channel_title,
       ROUND(AVG(total_engagement * 1.0 / trend_days), 2) AS avg_daily_engagement
FROM daily_engagement
GROUP BY channel_title
ORDER BY avg_daily_engagement DESC
LIMIT 5;

-- Q12: Find duplicate trending entries (same video_id appearing on multiple trending days)
SELECT video_id, title, COUNT(*) AS times_trending
FROM youtube_india_clean
GROUP BY video_id
HAVING times_trending > 1
ORDER BY times_trending DESC;

-- Q13: What percentage of videos have more likes than views (data issue check)?
SELECT 
    ROUND(CAST(SUM(CASE WHEN likes > views THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS FLOAT), 2) AS percent_invalid
FROM youtube_india_clean;

-- Q14: Find videos with missing or zero engagement
SELECT title, channel_title
FROM youtube_india_clean
WHERE likes = 0 AND dislikes = 0 AND comment_count = 0;

-- Q15: Top 5 channels with the most trending videos per category
WITH ranked_channels AS (
    SELECT channel_title, category_id, COUNT(*) AS trend_count,
           RANK() OVER (PARTITION BY category_id ORDER BY COUNT(*) DESC) AS rank_by_category
    FROM youtube_india_clean
    GROUP BY channel_title, category_id
)
SELECT *
FROM ranked_channels
WHERE rank_by_category <= 5;

