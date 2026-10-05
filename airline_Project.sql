CREATE DATABASE airline_project;
USE airline_project;

CREATE TABLE passenger_satisfaction (
  id INT, gender VARCHAR(10), age INT,
  customer_type VARCHAR(20), type_of_travel VARCHAR(20), travel_class VARCHAR(20),
  flight_distance INT, departure_delay INT, arrival_delay INT,
  time_convenience TINYINT, online_booking TINYINT, checkin_service TINYINT,
  online_boarding TINYINT, gate_location TINYINT, onboard_service TINYINT,
  seat_comfort TINYINT, leg_room TINYINT, cleanliness TINYINT,
  food_drink TINYINT, inflight_service TINYINT, wifi TINYINT,
  entertainment TINYINT, baggage_handling TINYINT,
  satisfaction VARCHAR(30)
);

CREATE TABLE airlines (iata_code VARCHAR(5), airline_name VARCHAR(60));

CREATE TABLE airports (
  iata_code VARCHAR(5), airport_name VARCHAR(120), city VARCHAR(60),
  state VARCHAR(5), country VARCHAR(10), latitude DECIMAL(9,5), longitude DECIMAL(9,5)
);

CREATE TABLE cancellation_codes (reason_code CHAR(1), description VARCHAR(50));

CREATE TABLE flights (
  month TINYINT, day TINYINT, day_of_week TINYINT,
  airline VARCHAR(5), origin_airport VARCHAR(10), destination_airport VARCHAR(10),
  scheduled_departure SMALLINT, departure_delay INT, arrival_delay INT,
  distance INT, diverted TINYINT, cancelled TINYINT, cancellation_reason CHAR(1),
  air_system_delay INT, security_delay INT, airline_delay INT,
  late_aircraft_delay INT, weather_delay INT
);

SHOW TABLES;

SET GLOBAL local_infile = 1;

USE airline_project;

LOAD DATA LOCAL INFILE 'C:/airline_project/airlines.csv'
INTO TABLE airlines
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 LINES
(iata_code, @n)
SET airline_name = TRIM(TRAILING '\r' FROM @n);

LOAD DATA LOCAL INFILE 'C:/airline_project/cancellation_codes.csv'
INTO TABLE cancellation_codes
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 LINES
(reason_code, @d)
SET description = TRIM(TRAILING '\r' FROM @d);

LOAD DATA LOCAL INFILE 'C:/airline_project/airports.csv'
INTO TABLE airports
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 LINES
(iata_code, airport_name, city, state, country, @lat, @lon)
SET latitude  = NULLIF(TRIM(@lat),''),
    longitude = NULLIF(TRIM(TRAILING '\r' FROM @lon),'');
    
    
SELECT COUNT(*) FROM airlines;            -- 14
SELECT COUNT(*) FROM cancellation_codes;  -- 4
SELECT COUNT(*) FROM airports;            -- 322
SELECT * FROM airlines;


LOAD DATA LOCAL INFILE 'C:/airline_project/airline_passenger_satisfaction.csv'
INTO TABLE passenger_satisfaction
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\r\n' IGNORE 1 LINES
(id, gender, age, customer_type, type_of_travel, travel_class,
 flight_distance, departure_delay, @arr,
 time_convenience, online_booking, checkin_service, online_boarding, gate_location,
 onboard_service, seat_comfort, leg_room, cleanliness, food_drink,
 inflight_service, wifi, entertainment, baggage_handling, satisfaction)
SET arrival_delay = NULLIF(@arr,'');

SELECT COUNT(*) FROM passenger_satisfaction;                              -- 129880
SELECT COUNT(*) FROM passenger_satisfaction WHERE arrival_delay IS NULL;  -- 393
SELECT * FROM passenger_satisfaction LIMIT 3;

SELECT COUNT(*) FROM passenger_satisfaction;   -- 129880 aana chahiye


USE airline_project;

LOAD DATA LOCAL INFILE 'C:/airline_project/flights.csv'
INTO TABLE flights
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 LINES
(@c1,@c2,@c3,@c4,@c5,@c6,@c7,@c8,@c9,@c10,@c11,@c12,@c13,@c14,@c15,@c16,
 @c17,@c18,@c19,@c20,@c21,@c22,@c23,@c24,@c25,@c26,@c27,@c28,@c29,@c30,@c31)
SET month=@c2, day=@c3, day_of_week=@c4, airline=@c5,
    origin_airport=@c8, destination_airport=@c9,
    scheduled_departure=NULLIF(@c10,''), departure_delay=NULLIF(@c12,''),
    distance=NULLIF(@c18,''), arrival_delay=NULLIF(@c23,''),
    diverted=@c24, cancelled=@c25, cancellation_reason=NULLIF(@c26,''),
    air_system_delay=NULLIF(@c27,''), security_delay=NULLIF(@c28,''),
    airline_delay=NULLIF(@c29,''), late_aircraft_delay=NULLIF(@c30,''),
    weather_delay=NULLIF(@c31,'');
    
SELECT COUNT(*) FROM flights;

SHOW INDEX FROM flights;

CREATE INDEX idx_f_airline ON flights(airline);
CREATE INDEX idx_f_month ON flights(month);
CREATE INDEX idx_f_origin ON flights(origin_airport);


USE airline_project;

-- Query 1: Overall Flight KPIs
-- Business Question: How many flights operated in 2015, and what share were cancelled or diverted?

-- Volume, cancellation and diversion rates (all flights)

SELECT COUNT(*)                       AS total_flights,
       ROUND(100 * AVG(cancelled), 2) AS cancellation_rate_pct,
       ROUND(100 * AVG(diverted), 2)  AS diversion_rate_pct
FROM flights;


-- Query 2: Airline Reliability Scorecard
-- Business Question: Which airlines are the most and least punctual?

SELECT a.airline_name,
       COUNT(*)                                              AS flights,
       ROUND(100 * SUM(f.arrival_delay > 15) / COUNT(*), 2)  AS delayed_pct,
       ROUND(AVG(f.departure_delay), 1)                      AS avg_departure_delay_min,
       RANK() OVER (ORDER BY SUM(f.arrival_delay > 15) / COUNT(*)) AS reliability_rank
FROM flights f
JOIN airlines a ON a.iata_code = f.airline
WHERE f.cancelled = 0
  AND f.diverted = 0
  AND f.arrival_delay IS NOT NULL
GROUP BY a.airline_name
ORDER BY reliability_rank;

-- Query 3: Cancellation Rate by Airline
-- Business Question: Which airlines cancel the largest share of their flights?

SELECT a.airline_name,
       COUNT(*)                         AS flights,
       SUM(f.cancelled)                 AS cancelled_flights,
       ROUND(100 * AVG(f.cancelled), 2) AS cancellation_rate_pct
FROM flights f
JOIN airlines a ON a.iata_code = f.airline
GROUP BY a.airline_name
ORDER BY cancellation_rate_pct DESC;


-- Query 4: Reasons for Cancellation
-- Business Question: Why are flights cancelled, and how much of it is within the airline's control?

SELECT c.description                                    AS cancellation_reason,
       COUNT(*)                                         AS cancelled_flights,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS share_pct
FROM flights f
JOIN cancellation_codes c ON c.reason_code = f.cancellation_reason
WHERE f.cancelled = 1
GROUP BY c.description
ORDER BY cancelled_flights DESC;


-- Query 5: Monthly Trend (seasonality)
-- Business Question: How do cancellations and delays change from month to month, and which months are the worst?

WITH cancel_stats AS (
    SELECT month,
           COUNT(*)                         AS flights,
           ROUND(100 * AVG(cancelled), 2)   AS cancellation_rate_pct
    FROM flights
    GROUP BY month
),
delay_stats AS (
    SELECT month,
           ROUND(100 * SUM(arrival_delay > 15) / COUNT(*), 2) AS delayed_pct
    FROM flights
    WHERE cancelled = 0 AND diverted = 0 AND arrival_delay IS NOT NULL
    GROUP BY month
)
SELECT c.month,
       c.flights,
       c.cancellation_rate_pct,
       d.delayed_pct,
       ROUND(d.delayed_pct - LAG(d.delayed_pct) OVER (ORDER BY c.month), 2) AS delayed_change_vs_prev_month
FROM cancel_stats c
JOIN delay_stats d ON d.month = c.month
ORDER BY c.month;

-- Query 6: Delays by Day of the Week
-- Business Question: Which days of the week have the highest share of delayed flights?

WITH daily AS (
    SELECT day_of_week,
           COUNT(*)                                             AS flights,
           ROUND(100 * SUM(arrival_delay > 15) / COUNT(*), 2)   AS delayed_pct
    FROM flights
    WHERE cancelled = 0 AND diverted = 0 AND arrival_delay IS NOT NULL
    GROUP BY day_of_week
)
SELECT CASE day_of_week
         WHEN 1 THEN 'Monday'    WHEN 2 THEN 'Tuesday'  WHEN 3 THEN 'Wednesday'
         WHEN 4 THEN 'Thursday'  WHEN 5 THEN 'Friday'   WHEN 6 THEN 'Saturday'
         ELSE 'Sunday' END                                AS weekday,
       flights,
       delayed_pct,
       RANK() OVER (ORDER BY delayed_pct DESC)            AS worst_day_rank
FROM daily
ORDER BY day_of_week;

-- Query 7: Delays by Time of Day
-- Business Question: At what time of day are flights most likely to be delayed?

WITH flown AS (
    SELECT FLOOR(scheduled_departure / 100) AS dep_hour,
           arrival_delay
    FROM flights
    WHERE cancelled = 0 AND diverted = 0 AND arrival_delay IS NOT NULL
),
blocks AS (
    SELECT CASE WHEN dep_hour < 6  THEN '1. Early Morning (00-05)'
                WHEN dep_hour < 12 THEN '2. Morning (06-11)'
                WHEN dep_hour < 18 THEN '3. Afternoon (12-17)'
                ELSE '4. Evening (18-23)' END AS time_block,
           arrival_delay
    FROM flown
)
SELECT time_block,
       COUNT(*)                                             AS flights,
       ROUND(100 * SUM(arrival_delay > 15) / COUNT(*), 2)   AS delayed_pct
FROM blocks
GROUP BY time_block
ORDER BY time_block;

-- Query 8: Main Causes of Delay
-- Business Question: Which cause accounts for the largest share of total delay minutes?

WITH causes AS (
    SELECT 'Late Aircraft'   AS cause, SUM(late_aircraft_delay) AS delay_minutes FROM flights
    UNION ALL
    SELECT 'Airline',         SUM(airline_delay)      FROM flights
    UNION ALL
    SELECT 'Air System',      SUM(air_system_delay)   FROM flights
    UNION ALL
    SELECT 'Weather',         SUM(weather_delay)      FROM flights
    UNION ALL
    SELECT 'Security',        SUM(security_delay)     FROM flights
)
SELECT cause,
       delay_minutes,
       ROUND(100 * delay_minutes / SUM(delay_minutes) OVER (), 1) AS share_pct
FROM causes
ORDER BY delay_minutes DESC;

-- Query 9: Airports with the Highest Delay Rates
-- Business Question: Which large airports have the highest share of delayed departures?

WITH airport_stats AS (
    SELECT origin_airport,
           COUNT(*)                                             AS flights,
           ROUND(100 * SUM(arrival_delay > 15) / COUNT(*), 2)   AS delayed_pct
    FROM flights
    WHERE cancelled = 0 AND diverted = 0 AND arrival_delay IS NOT NULL
      AND CHAR_LENGTH(origin_airport) = 3
    GROUP BY origin_airport
    HAVING COUNT(*) >= 20000
)
SELECT s.origin_airport  AS airport_code,
       ap.airport_name,
       ap.state,
       s.flights,
       s.delayed_pct,
       RANK() OVER (ORDER BY s.delayed_pct DESC) AS worst_rank
FROM airport_stats s
JOIN airports ap ON ap.iata_code = s.origin_airport
ORDER BY worst_rank
LIMIT 10;


-- Query 10: Each Airline vs the Industry Average
-- Business Question: Which airlines perform better or worse than the industry average for delays?

WITH flown AS (
    SELECT airline, arrival_delay
    FROM flights
    WHERE cancelled = 0 AND diverted = 0 AND arrival_delay IS NOT NULL
),
industry AS (
    SELECT ROUND(100 * SUM(arrival_delay > 15) / COUNT(*), 2) AS industry_delayed_pct
    FROM flown
),
airline_stats AS (
    SELECT airline,
           COUNT(*)                                             AS flights,
           ROUND(100 * SUM(arrival_delay > 15) / COUNT(*), 2)   AS delayed_pct
    FROM flown
    GROUP BY airline
)
SELECT a.airline_name,
       s.flights,
       s.delayed_pct,
       i.industry_delayed_pct,
       ROUND(s.delayed_pct - i.industry_delayed_pct, 2) AS gap_vs_industry_pts,
       CASE WHEN s.delayed_pct < i.industry_delayed_pct
            THEN 'Better than industry' ELSE 'Worse than industry' END AS performance
FROM airline_stats s
CROSS JOIN industry i
JOIN airlines a ON a.iata_code = s.airline
ORDER BY gap_vs_industry_pts;

-- Query 11: Overall Satisfaction
-- Business Question: What share of surveyed passengers are satisfied with the airline?

WITH overall AS (
    SELECT COUNT(*)                                   AS total_passengers,
           SUM(satisfaction = 'Satisfied')            AS satisfied_passengers
    FROM passenger_satisfaction
)
SELECT total_passengers,
       satisfied_passengers,
       ROUND(100 * satisfied_passengers / total_passengers, 2) AS satisfied_pct
FROM overall;


-- Query 12: Satisfaction by Passenger Segment
-- Business Question: Which types of passengers (class, travel purpose, customer type) are the most and least satisfied?

WITH overall AS (
    SELECT 100 * SUM(satisfaction = 'Satisfied') / COUNT(*) AS overall_pct
    FROM passenger_satisfaction
),
segments AS (
    SELECT 'Class' AS segment_type, travel_class AS segment, satisfaction FROM passenger_satisfaction
    UNION ALL
    SELECT 'Travel purpose', type_of_travel, satisfaction FROM passenger_satisfaction
    UNION ALL
    SELECT 'Customer type', customer_type, satisfaction FROM passenger_satisfaction
)
SELECT s.segment_type,
       s.segment,
       COUNT(*)                                                    AS passengers,
       ROUND(100 * SUM(s.satisfaction = 'Satisfied') / COUNT(*), 2) AS satisfied_pct,
       ROUND(100 * SUM(s.satisfaction = 'Satisfied') / COUNT(*) - o.overall_pct, 2) AS gap_vs_overall_pts
FROM segments s
CROSS JOIN overall o
GROUP BY s.segment_type, s.segment, o.overall_pct
ORDER BY s.segment_type, satisfied_pct DESC;


-- Query 13: Satisfaction by Age Group
-- Business Question: Which age groups are the most and least satisfied?

WITH aged AS (
    SELECT CASE WHEN age < 18  THEN '1. Under 18'
                WHEN age <= 35 THEN '2. 18-35'
                WHEN age <= 55 THEN '3. 36-55'
                ELSE '4. 56+' END AS age_group,
           satisfaction
    FROM passenger_satisfaction
)
SELECT age_group,
       COUNT(*)                                                    AS passengers,
       ROUND(100 * SUM(satisfaction = 'Satisfied') / COUNT(*), 2)   AS satisfied_pct
FROM aged
GROUP BY age_group
ORDER BY age_group;

-- Query 14: Effect of Delay on Satisfaction
-- Business Question: Does a longer arrival delay lower passenger satisfaction?

WITH delay_groups AS (
    SELECT CASE WHEN arrival_delay IS NULL THEN '5. Unknown'
                WHEN arrival_delay <= 0    THEN '1. On time'
                WHEN arrival_delay <= 30   THEN '2. 1-30 min'
                WHEN arrival_delay <= 60   THEN '3. 31-60 min'
                ELSE '4. 60+ min' END AS delay_bucket,
           satisfaction
    FROM passenger_satisfaction
)
SELECT delay_bucket,
       COUNT(*)                                                    AS passengers,
       ROUND(100 * SUM(satisfaction = 'Satisfied') / COUNT(*), 2)   AS satisfied_pct
FROM delay_groups
GROUP BY delay_bucket
ORDER BY delay_bucket;

-- Query 15: Key Drivers of Satisfaction (most important query)
-- Business Question: Which service factors differ the most between satisfied and unsatisfied passengers?

WITH ratings AS (
    SELECT 'Online Boarding' AS factor, (satisfaction = 'Satisfied') AS is_satisfied, NULLIF(online_boarding, 0) AS rating FROM passenger_satisfaction
    UNION ALL SELECT 'In-flight Entertainment', (satisfaction = 'Satisfied'), NULLIF(entertainment, 0)     FROM passenger_satisfaction
    UNION ALL SELECT 'In-flight Wifi',          (satisfaction = 'Satisfied'), NULLIF(wifi, 0)              FROM passenger_satisfaction
    UNION ALL SELECT 'Seat Comfort',            (satisfaction = 'Satisfied'), NULLIF(seat_comfort, 0)      FROM passenger_satisfaction
    UNION ALL SELECT 'On-board Service',        (satisfaction = 'Satisfied'), NULLIF(onboard_service, 0)   FROM passenger_satisfaction
    UNION ALL SELECT 'Leg Room',                (satisfaction = 'Satisfied'), NULLIF(leg_room, 0)          FROM passenger_satisfaction
    UNION ALL SELECT 'Cleanliness',             (satisfaction = 'Satisfied'), NULLIF(cleanliness, 0)       FROM passenger_satisfaction
    UNION ALL SELECT 'Ease of Online Booking',  (satisfaction = 'Satisfied'), NULLIF(online_booking, 0)    FROM passenger_satisfaction
    UNION ALL SELECT 'Check-in Service',        (satisfaction = 'Satisfied'), NULLIF(checkin_service, 0)   FROM passenger_satisfaction
    UNION ALL SELECT 'Baggage Handling',        (satisfaction = 'Satisfied'), NULLIF(baggage_handling, 0)  FROM passenger_satisfaction
    UNION ALL SELECT 'In-flight Service',       (satisfaction = 'Satisfied'), NULLIF(inflight_service, 0)  FROM passenger_satisfaction
    UNION ALL SELECT 'Food and Drink',          (satisfaction = 'Satisfied'), NULLIF(food_drink, 0)        FROM passenger_satisfaction
    UNION ALL SELECT 'Gate Location',           (satisfaction = 'Satisfied'), NULLIF(gate_location, 0)     FROM passenger_satisfaction
    UNION ALL SELECT 'Departure/Arrival Time Convenience', (satisfaction = 'Satisfied'), NULLIF(time_convenience, 0) FROM passenger_satisfaction
),
factor_scores AS (
    SELECT factor,
           ROUND(AVG(CASE WHEN is_satisfied = 1 THEN rating END), 2) AS avg_rating_satisfied,
           ROUND(AVG(CASE WHEN is_satisfied = 0 THEN rating END), 2) AS avg_rating_unsatisfied
    FROM ratings
    GROUP BY factor
)
SELECT factor,
       avg_rating_satisfied,
       avg_rating_unsatisfied,
       ROUND(avg_rating_satisfied - avg_rating_unsatisfied, 2) AS rating_gap,
       RANK() OVER (ORDER BY avg_rating_satisfied - avg_rating_unsatisfied DESC) AS driver_rank
FROM factor_scores
ORDER BY driver_rank;

-- Query 16: Class Ranking within Each Travel Purpose
-- Business Question: For business and personal travellers, which class is the most satisfied?

WITH combo AS (
    SELECT type_of_travel,
           travel_class,
           COUNT(*)                                                    AS passengers,
           ROUND(100 * SUM(satisfaction = 'Satisfied') / COUNT(*), 2)   AS satisfied_pct
    FROM passenger_satisfaction
    GROUP BY type_of_travel, travel_class
)
SELECT type_of_travel,
       travel_class,
       passengers,
       satisfied_pct,
       RANK() OVER (PARTITION BY type_of_travel ORDER BY satisfied_pct DESC) AS rank_within_travel_type
FROM combo
ORDER BY type_of_travel, rank_within_travel_type;

-- Query 17: Least Satisfied Passenger Segments
-- Business Question: Which specific groups of passengers should the airline prioritise for improvement?

WITH segment_stats AS (
    SELECT type_of_travel,
           travel_class,
           customer_type,
           COUNT(*)                                                    AS passengers,
           ROUND(100 * SUM(satisfaction = 'Satisfied') / COUNT(*), 2)   AS satisfied_pct
    FROM passenger_satisfaction
    GROUP BY type_of_travel, travel_class, customer_type
    HAVING COUNT(*) >= 1000
)
SELECT type_of_travel,
       travel_class,
       customer_type,
       passengers,
       satisfied_pct,
       RANK() OVER (ORDER BY satisfied_pct) AS lowest_satisfaction_rank
FROM segment_stats
ORDER BY lowest_satisfaction_rank
LIMIT 5;

-- Part 1: Stored Procedure (reusable airline report)
-- Business Question: Can a manager get a one-click performance report for any airline by entering its code?

DROP PROCEDURE IF EXISTS airline_report;

DELIMITER //
CREATE PROCEDURE airline_report(IN p_code VARCHAR(5))
BEGIN
    SELECT a.airline_name,
           COUNT(*)                          AS total_flights,
           SUM(f.cancelled)                  AS cancelled_flights,
           ROUND(100 * AVG(f.cancelled), 2)  AS cancellation_rate_pct,
           ROUND(100 * SUM(CASE WHEN f.cancelled = 0 AND f.diverted = 0
                                 AND f.arrival_delay IS NOT NULL
                                 AND f.arrival_delay > 15 THEN 1 ELSE 0 END)
                 / NULLIF(SUM(CASE WHEN f.cancelled = 0 AND f.diverted = 0
                                    AND f.arrival_delay IS NOT NULL THEN 1 ELSE 0 END), 0), 2) AS delayed_pct
    FROM flights f
    JOIN airlines a ON a.iata_code = f.airline
    WHERE f.airline = p_code
    GROUP BY a.airline_name;
END //
DELIMITER ;


CALL airline_report('HA');
CALL airline_report('DL');
CALL airline_report('NK');

-- Part 2: Index Proof (EXPLAIN)
-- Business Question: Did the indexes actually make queries faster?

-- Test 1: index ke saath
SELECT COUNT(*) FROM flights WHERE airline = 'DL';
EXPLAIN SELECT COUNT(*) FROM flights WHERE airline = 'DL';

-- Test 2: index ke bina
SELECT COUNT(*) FROM flights IGNORE INDEX (idx_f_airline) WHERE airline = 'DL';
EXPLAIN SELECT COUNT(*) FROM flights IGNORE INDEX (idx_f_airline) WHERE airline = 'DL';


-- Part 3: Views for the Dashboard
-- Business Question: How can the results be reused in a dashboard without rewriting queries?

-- View 1: Airline scorecard
CREATE OR REPLACE VIEW vw_airline_scorecard AS
SELECT a.airline_name,
       t.total_flights,
       t.cancellation_rate_pct,
       t.delayed_pct,
       t.avg_departure_delay_min
FROM (
    SELECT airline,
           COUNT(*)                         AS total_flights,
           ROUND(100 * AVG(cancelled), 2)   AS cancellation_rate_pct,
           ROUND(100 * SUM(CASE WHEN cancelled = 0 AND diverted = 0
                                 AND arrival_delay IS NOT NULL AND arrival_delay > 15 THEN 1 ELSE 0 END)
                 / SUM(CASE WHEN cancelled = 0 AND diverted = 0
                             AND arrival_delay IS NOT NULL THEN 1 ELSE 0 END), 2) AS delayed_pct,
           ROUND(AVG(departure_delay), 1)   AS avg_departure_delay_min
    FROM flights
    GROUP BY airline
) t
JOIN airlines a ON a.iata_code = t.airline;

-- View 2: Monthly trend

CREATE OR REPLACE VIEW vw_monthly_trend AS
SELECT month,
       COUNT(*)                         AS total_flights,
       ROUND(100 * AVG(cancelled), 2)   AS cancellation_rate_pct,
       ROUND(100 * SUM(CASE WHEN cancelled = 0 AND diverted = 0
                             AND arrival_delay IS NOT NULL AND arrival_delay > 15 THEN 1 ELSE 0 END)
             / SUM(CASE WHEN cancelled = 0 AND diverted = 0
                         AND arrival_delay IS NOT NULL THEN 1 ELSE 0 END), 2) AS delayed_pct
FROM flights
GROUP BY month;

-- View 3: Satisfaction segments

CREATE OR REPLACE VIEW vw_satisfaction_segments AS
SELECT 'Class' AS segment_type, travel_class AS segment,
       COUNT(*) AS passengers,
       ROUND(100 * SUM(satisfaction = 'Satisfied') / COUNT(*), 2) AS satisfied_pct
FROM passenger_satisfaction GROUP BY travel_class
UNION ALL
SELECT 'Travel purpose', type_of_travel, COUNT(*),
       ROUND(100 * SUM(satisfaction = 'Satisfied') / COUNT(*), 2)
FROM passenger_satisfaction GROUP BY type_of_travel
UNION ALL
SELECT 'Customer type', customer_type, COUNT(*),
       ROUND(100 * SUM(satisfaction = 'Satisfied') / COUNT(*), 2)
FROM passenger_satisfaction GROUP BY customer_type;

-- View 4: Satisfaction drivers

USE airline_project;

CREATE OR REPLACE VIEW vw_satisfaction_drivers AS
WITH ratings AS (
    SELECT 'Online Boarding' AS factor, (satisfaction = 'Satisfied') AS is_satisfied, NULLIF(online_boarding, 0) AS rating FROM passenger_satisfaction
    UNION ALL SELECT 'In-flight Entertainment', (satisfaction = 'Satisfied'), NULLIF(entertainment, 0)     FROM passenger_satisfaction
    UNION ALL SELECT 'In-flight Wifi',          (satisfaction = 'Satisfied'), NULLIF(wifi, 0)              FROM passenger_satisfaction
    UNION ALL SELECT 'Seat Comfort',            (satisfaction = 'Satisfied'), NULLIF(seat_comfort, 0)      FROM passenger_satisfaction
    UNION ALL SELECT 'On-board Service',        (satisfaction = 'Satisfied'), NULLIF(onboard_service, 0)   FROM passenger_satisfaction
    UNION ALL SELECT 'Leg Room',                (satisfaction = 'Satisfied'), NULLIF(leg_room, 0)          FROM passenger_satisfaction
    UNION ALL SELECT 'Cleanliness',             (satisfaction = 'Satisfied'), NULLIF(cleanliness, 0)       FROM passenger_satisfaction
    UNION ALL SELECT 'Ease of Online Booking',  (satisfaction = 'Satisfied'), NULLIF(online_booking, 0)    FROM passenger_satisfaction
    UNION ALL SELECT 'Check-in Service',        (satisfaction = 'Satisfied'), NULLIF(checkin_service, 0)   FROM passenger_satisfaction
    UNION ALL SELECT 'Baggage Handling',        (satisfaction = 'Satisfied'), NULLIF(baggage_handling, 0)  FROM passenger_satisfaction
    UNION ALL SELECT 'In-flight Service',       (satisfaction = 'Satisfied'), NULLIF(inflight_service, 0)  FROM passenger_satisfaction
    UNION ALL SELECT 'Food and Drink',          (satisfaction = 'Satisfied'), NULLIF(food_drink, 0)        FROM passenger_satisfaction
    UNION ALL SELECT 'Gate Location',           (satisfaction = 'Satisfied'), NULLIF(gate_location, 0)     FROM passenger_satisfaction
    UNION ALL SELECT 'Departure/Arrival Time Convenience', (satisfaction = 'Satisfied'), NULLIF(time_convenience, 0) FROM passenger_satisfaction
),
factor_scores AS (
    SELECT factor,
           ROUND(AVG(CASE WHEN is_satisfied = 1 THEN rating END), 2) AS avg_rating_satisfied,
           ROUND(AVG(CASE WHEN is_satisfied = 0 THEN rating END), 2) AS avg_rating_unsatisfied
    FROM ratings
    GROUP BY factor
)
SELECT factor,
       avg_rating_satisfied,
       avg_rating_unsatisfied,
       ROUND(avg_rating_satisfied - avg_rating_unsatisfied, 2) AS rating_gap,
       RANK() OVER (ORDER BY avg_rating_satisfied - avg_rating_unsatisfied DESC) AS driver_rank
FROM factor_scores;


-- Check 
SELECT * FROM vw_satisfaction_drivers ORDER BY driver_rank;

SELECT * FROM vw_airline_scorecard;
SELECT * FROM vw_monthly_trend;
SELECT * FROM vw_satisfaction_segments;
SELECT * FROM vw_satisfaction_drivers;

-- EXPORTS
USE airline_project;
SELECT * FROM vw_airline_scorecard;
SELECT * FROM vw_monthly_trend;
SELECT * FROM vw_satisfaction_segments;
SELECT * FROM vw_satisfaction_drivers;
