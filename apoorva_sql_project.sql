select * from teams;
select * from stadium;
--1)Count the Total Number of Teams
select count(distinct team_name) as Total_number_of_teams from teams;

--2)Find the Number of Teams per Country
select count(team_name) as number_of_teams_per_country, country
from teams group by country order by number_of_teams_per_country asc;

--3)Calculate the Average Team Name Length
select avg(length(team_name)) as Average_Team_Name_Length from teams;

--4)Calculate the Average Stadium Capacity in Each Country round it off and sort by the total stadiums in the country.
select round(avg(capacity)) as Average_Stadium_Capacity_in_Each_Country,count(name) as 
the_total_stadiums_in_the_country, country
from stadium group by country order by the_total_stadiums_in_the_country asc;

--5)Calculate the Total Goals Scored.
select count(goal_id) as total_number_of_goals_scored from Goals;

/*alter table teams drop primary key;

ALTER TABLE teams
DROP CONSTRAINT teams_pkey ;

ALTER TABLE stadium ADD PRIMARY KEY(name);

SELECT conname FROM pg_constraint
WHERE conrelid = 'teams'::regclass AND contype = 'p';*/

--6)Find the total teams that have city in their names
select count(a.team_name)
from teams as a left join stadium as b
on a.home_stadium=b.name 
where a.team_name like '%'|| b.city || '%' ;

--7) Use Text Functions to Concatenate the Team's Name and Country
select team_name || ', ' || country  as team_identity 
from teams;

--8) What is the highest attendance recorded in the dataset,
--and which match (including home and away teams, and date) does it correspond to?
select * from matches;
select attendence, home_team, away_team, date
from matches
where attendence =  (select max(attendence) from matches);

--9)What is the lowest attendance recorded in the dataset, and which match 
--(including home and away teams, and date) does it
--correspond to set the criteria as greater than 1 as some matches had 0 attendance because of covid.
select attendence, home_team,away_team,date
from matches where attendence = (select min(attendence) from matches);            
--no it doesn't satisfy set criteria because minimum attendence is 0

select * from matches;
--10) Identify the match with the highest total score (sum of home and away team scores) in the dataset.
--Include the match ID, home and away teams, and the total score
select home_team_score + away_team_score as total_score, match_id,home_team,away_team
from matches
where home_team_score + away_team_score=(select max(home_team_score + away_team_score) from matches);

--11)Find the total goals scored by each team, distinguishing between home and away goals. Use a CASE
--WHEN statement to differentiate home and away goals within the subquery
select * from Goals;
select * from teams;

/*select sum(home_goals)as total_goals_as_home_team, sum(away_goals) as total_goals_as_away_team, team
from ((select home_team as team, home_team_score as home_goals,0 as away_goals from matches)
	 union all (select away_team as team,0 as home_goals, away_team_score as away_goals from matches) )as final_table 
group by team;*/

select team,
sum(case when team = home_team then home_team_score else 0 end  ) as total_goals_as_home_team,
sum(case when team = away_team then away_team_score else 0 end  ) as total_goals_as_away_team
from ((select home_team as team, home_team,away_team,home_team_score,away_team_score from matches)
	 union all (select away_team as team, home_team ,away_team, home_team_score,away_team_score from matches) )as final_table 
group by team;

--12) windows function - Rank teams based on their total scored goals (home and away combined) 
--using a window function.In the stadium Old Trafford.
select total_goals_by_team,team, stadium,
rank() over (partition by stadium order by total_goals_by_team desc) as goal_rank
from(
select sum(home_goals+away_goals) as total_goals_by_team,team, stadium
from ((select home_team as team, home_team_score as home_goals,0 as away_goals, stadium from matches)
	 union all (select away_team as team,0 as home_goals, away_team_score as away_goals, stadium from matches) )as final_table 
group by team, stadium) as new_match
where stadium = 'Old Trafford';

/*select sum(home_goals+away_goals) as total_goals,team, stadium
from ((select home_team as team, home_team_score as home_goals,0 as away_goals, stadium from matches)
	 union all (select away_team as team,0 as home_goals, away_team_score as away_goals, stadium from matches) )as final_table 
group by team, stadium ;

select sum(home_team_score) from matches where (home_team = 'Manchester United' or away_team = 'Manchester United') and stadium = 'Old Trafford';*/

--13) TOP 5 l players who scored the most goals in Old Trafford, 
--ensuring null values are not included in the result (especially pertinent for cases where a player might not have scored any goals).
select * from players;
select * from teams
select * from matches
select * from goals order by pid desc
select * from stadium

select * , dense_rank() over (partition by stadium order by goals_by_player desc ) as rank_p from
(select count(g.goal_id) as goals_by_player, g.match_id, m.stadium ,g.pid  from 
goals as g inner join matches as m
on g.match_id = m.match_id group by g.pid, g.match_id, m.stadium) as new_table
where (stadium = 'Old Trafford') and (pid is not null)
limit 5 ;

--select count(g.goal_id) as goals_by_player, g.match_id, m.stadium ,g.pid  from 
--goals as g inner join matches as m
--on g.match_id = m.match_id group by g.pid, g.match_id, m.stadium order by g.pid desc

--14)Write a query to list all players along with the total number of goals they have scored. Order the results by the number of goals 
--scored in descending order to easily identify the top 6 scorers
with rank_table as (
select *,  rank() over (order by goals_by_player desc) as ranks from(
select  count(g.goal_id) as goals_by_player, p.player_id 
from players as p inner join goals as g on p.player_id=g.pid 
group by p.player_id) as new_table )
select * from rank_table where ranks<=6;

--14 ? top scorer
--15)Identify the Top Scorer for Each Team - Find the player from each team who has scored the most 
--goals in all matches combined. 
--This question requires joining the Players, Goals, and possibly the Matches tables, 
--and then using a subquery to aggregate goals by players and teams.
select * from teams;
select * from players;
select * from goals;
select * from matches order by season desc;

with rank_table as 
(select m.match_id, g.goal_id,g.pid from goals as g inner join matches as m
on g.match_id=m.match_id order by g.pid desc),
goal_table as (
select count(r.goal_id) as goals_per_player, p.player_id, p.team
from players as p inner join rank_table as r on r.pid=p.player_id group by p.player_id,p.team )
, goals_count_table as (
select *, rank() over (partition by team order by goals_per_player desc) as ranks
from goal_table ) 
select goals_count_table.goals_per_player,goals_count_table.player_id,goals_count_table.team
from goals_count_table where ranks = 1;

--16)Find the Total Number of Goals Scored in the Latest Season -
--Calculate the total number of goals scored in the latest season available
--in the dataset. This question involves using a subquery to first identify 
--the latest season from the Matches table, then summing the goals from the Goals table
--that occurred in matches from that season.

select count(g.goal_id)as total_goals, m.season
from matches as m inner join goals as g on m.match_id=g.match_id
where m.season in (select season from matches order by season desc limit 1)
group by m.season ;

--17)Find Matches with Above Average Attendance - Retrieve a list of matches that had an attendance
--higher than the average attendance across all matches. This question requires a subquery to calculate
--the average attendance first, then use it to filter matches.
select * from matches;
select match_id from matches where attendence >(select avg(attendence) from matches); 

--18)Find the Number of Matches Played Each Month - Count how many matches were played in
--each month across all seasons. This question requires extracting the month from the match dates
--and grouping the results by this value. as January Feb march
select TO_CHAR(date::date, 'Month') as match_month,
count(match_id) as matches_played_each_month
from matches group by match_month ;