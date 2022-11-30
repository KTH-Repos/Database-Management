--How many fines were paid with a card in september 2021?
SELECT COUNT(transactionID) AS septemberfines
FROM TRANSACTIONS 
WHERE paymentMethod = 'Card' AND (DoP >= '2021-09-01' AND DoP <= '2021-09-30');

--Which student has read the most amount of pages? (!!!Check if correct)
SELECT name, SUM(pages) as pages 
FROM Borrowing, Users, Resources, Books 
WHERE (Borrowing.userID = Users.userID) AND (Resources.bookID = Books.bookID) 
GROUP BY name
ORDER BY pages DESC;

--Present all currently available books with a little starting S and ending in S or a title starting with H and ending in S. 
--The first query gives a table with 11 entries. 
--The second query gives a table with 5 entires. 
-- SELECT title 
-- FROM Books 
-- WHERE ((title LIKE 'S%') AND title LIKE '%s') OR (title LIKE 'H%') AND title LIKE '%s';

-- selects books that actually have copies
SELECT DISTINCT title 
FROM Books, Resources, Borrowing 
WHERE (((title LIKE 'S%') AND title LIKE '%s') OR (title LIKE 'H%') AND title LIKE '%s') AND Borrowing.physicalID = Resources.physicalID AND Resources.bookID = Books.bookID;

--Rank the top 3 most popular books per genre. 
--Warning; repititon of book titles who have more than one genre
WITH CTE_popularbooks AS (
    SELECT title, genre, COUNT(Borrowing.physicalID) AS borrowedtimes
    FROM Books, Resources, Genre, Borrowing 
    WHERE (Borrowing.physicalID = Resources.physicalID AND Resources.bookID = Books.bookID) AND Books.bookID = Genre.bookID
    GROUP BY title, genre
), popularbooks_ranked AS (
    SELECT title, genre, rank() OVER (ORDER BY borrowedtimes DESC) AS rank
    FROM CTE_popularbooks
)
    SELECT title, genre, rank
    FROM popularbooks_ranked
    WHERE rank <= 3
    ORDER BY title;



--Which program has the greatest sum of fines? Present all the programs' percentage of the total sum of fines. 
--sum(amount) = 33358 kr.
--Warning: without the GROUP BY statement the query doesn't work. 
SELECT program, sum(amount) as sum, sum(amount)*100.0/(SELECT sum(amount) FROM Fines) as percentage
FROM Fines, Borrowing, Students
WHERE (BORROWING.BorrowingID=FINES.borrowingID) AND (BORROWING.userID=Students.userID)
GROUP BY program
ORDER BY sum DESC;

--Rank the top 5 of the all time most popular books in the romcom genre based on the amount of times they've been borrowed. 
--Complete solution
WITH CTE_borrowedromcom AS (
    SELECT title, COUNT(Borrowing.physicalID) AS count
    FROM Resources, Genre, Borrowing, Books
    WHERE (Borrowing.physicalID=Resources.physicalID) AND (Resources.bookID=Genre.bookID) AND (Books.bookID=Genre.bookID) AND (Genre.genre='RomCom')
    GROUP BY title
), rankedbooks AS (

SELECT title, RANK() OVER (ORDER BY count DESC) AS rank
FROM CTE_borrowedromcom
)
SELECT *
FROM rankedbooks
WHERE rank <= 5;


--Present the likelihood that a top 10% popular book will be returned late. 
-- individual arbitrary likelihood for the top 10% popular books

-- -- one arbitrary likelihood for the top 10% popular books
-- WITH all_loans AS (
--     SELECT Books.bookID, title, COUNT(Borrowing.physicalID) AS borrowed_times
--     FROM Borrowing, Resources, Books
--     WHERE (Borrowing.physicalID = Resources.physicalID AND Resources.bookID = Books.bookID)
--     GROUP BY Books.bookID, title
-- ), ranked_popularbooks AS (
--     SELECT bookID, title, rank() OVER (ORDER BY borrowed_times DESC) AS rank
--     FROM all_loans
-- ), top_ten AS (
--     SELECT bookID, title, rank
--     FROM ranked_popularbooks
--     GROUP BY bookID, title, rank
--     ORDER BY rank ASC
--     LIMIT (SELECT (COUNT(rank) / 10) from ranked_popularbooks)
-- ), late_returned_books AS (
--     SELECT Books.bookID, COUNT(Borrowing.physicalID) as late
--     FROM Borrowing, Fines, Resources, Books
--     WHERE (Fines.borrowingID = Borrowing.borrowingID) AND (Borrowing.physicalID = Resources.physicalID AND Resources.bookID = Books.bookID)
--     GROUP BY Books.bookID
-- ), top_ten_late_books AS (
--     SELECT top_ten.bookID, title, rank, late
--     FROM top_ten, late_returned_books
--     WHERE top_ten.bookID = late_returned_books.bookID
--     GROUP BY top_ten.bookID, title, rank, late
--     ORDER BY top_ten.bookID, rank ASC
-- )
--     SELECT (SUM(top_ten_late_books.late) / SUM(all_loans.borrowed_times)*1.0)*100 || ' %' as likelihood
--     FROM top_ten_late_books, all_loans
--     ORDER BY likelihood DESC;

-----------------------------------------------------------------------------

WITH popularbooks AS (
    SELECT Borrowing.physicalID, COUNT(Borrowing.physicalID) AS borrowed_times
    FROM Borrowing
    GROUP BY Borrowing.physicalID
), latebooks AS (
    SELECT physicalID, COUNT(Fines.borrowingID) AS late
    FROM Borrowing JOIN Fines ON Fines.borrowingID=Borrowing.borrowingID
    GROUP BY physicalID
), resourcess AS (
    SELECT popularbooks.physicalID, popularbooks.borrowed_times, latebooks.late
    FROM popularbooks JOIN latebooks ON popularbooks.physicalID=latebooks.physicalID
    GROUP BY popularbooks.physicalID, popularbooks.borrowed_times, latebooks.late
), reswithtitles AS ( 
    SELECT title, resourcess.physicalID, resourcess.borrowed_times, resourcess.late
    FROM resources, resourcess, books
    WHERE resources.physicalID=resourcess.physicalID AND resources.bookID=books.bookID
), top_ten as (
    SELECT reswithtitles.title, SUM(reswithtitles.borrowed_times) AS borrowed_times, SUM(reswithtitles.late) AS late
    FROM reswithtitles
    GROUP BY reswithtitles.title
    ORDER BY borrowed_times DESC
), ranked as (
    SELECT title, borrowed_times, late, rank() OVER (ORDER BY borrowed_times DESC) AS rank
    FROM top_ten
    GROUP BY title, borrowed_times, late
    ORDER BY rank ASC
), top_ten_ranked as (
    SELECT *
    FROM ranked
    WHERE rank <= 6
)
    SELECT ((SUM(late) / SUM(borrowed_times)*1.0)*100) || ' %' as likelihood
    FROM top_ten_ranked;


    


-- WHERE (DoR IS NOT NULL AND (DoR - DoE > 0));

-- DoR (date of return) IS NOT NULL --> book has been returned
-- DoR (date of return) - DoE (date of expiry), if larger than 0, book has been returned late


-- Present a report for each week from the first week in January to the first week in June this year (2021) on how
-- many books were borrowed, returned and late. 
WITH CTE_late AS (
    SELECT DATE_PART('week', DoB) AS test, COUNT(borrowingID) as late
    FROM Borrowing
    WHERE DoR > Doe AND (DoB >= '2021-01-04' AND DoB <= '2021-06-07')
    GROUP BY DATE_PART('week', DoB)
), CTE_info AS (
    SELECT DATE_PART('week', DoB) AS Week, 
    COUNT(borrowingID) AS borrowed, 
    COUNT(DoR) AS returned
    FROM Borrowing
    WHERE (DoB >= '2021-01-04' AND DoB <= '2021-06-07')
    GROUP BY DATE_PART('week', DoB)
)
    SELECT Week, borrowed, returned, CTE_late.late
    FROM CTE_info JOIN CTE_late ON CTE_info.Week = CTE_late.test
    GROUP BY Week, borrowed, returned, CTE_late.late
    ORDER BY Week;



--For each book series, use the recursive method to present the name of each book in the series in order. 

WITH RECURSIVE series AS (
    WITH seqtitles AS ( 
        SELECT books.bookID, title, prequels.prequelID
        FROM Books JOIN prequels ON prequels.bookID=books.bookID
    ), preseqtitles AS (
        SELECT prequelID, title
        FROM prequels, Books
        WHERE Books.bookID=prequels.prequelID
    ), final AS (
        SELECT seqtitles.bookID, seqtitles.title AS seqtitle, seqtitles.prequelID, preseqtitles.title AS preseqtitle
        FROM seqtitles JOIN preseqtitles ON seqtitles.prequelID=preseqtitles.prequelID
    )
    (SELECT prequelID, bookID, preseqtitle ||' -> '||seqtitle AS link, 1 AS lev 
     FROM final
     WHERE NOT EXISTS (SELECT * FROM final WHERE final.bookID=final.prequelID))
     UNION
    (SELECT series.prequelID, final.bookID, link ||' -> '||seqtitle, lev+1
    FROM series JOIN final ON series.bookID=final.prequelID)
)
SELECT link
FROM
(
    SELECT DISTINCT ON (series.prequelID) series.prequelID, link
    FROM series, prequels
    WHERE series.prequelID NOT IN (SELECT bookID FROM prequels)
    ORDER BY series.prequelID, link DESC
) AS FOO;



/* WITH RECURSIVE series AS (
    (SELECT prequelID, bookID, prequelID ||' -> '||bookID AS link, 1 AS lev 
     FROM Prequels
     WHERE NOT EXISTS (SELECT 1 FROM prequels WHERE prequels.bookID=prequels.prequelID))
     UNION
    (SELECT series.prequelID, prequels.bookID, link ||' -> '||prequels.bookID, lev+1
      FROM series JOIN prequels ON series.bookID=prequels.prequelID)
)
SELECT DISTINCT ON (prequelID)*
FROM series
ORDER BY prequelID, lev DESC; */
 /* prequelid | bookid
-----------+--------
      2985 |  30553
      7458 |   2985
     74532 |   8713
     90293 |  74532
     37822 |  90293
      3747 |  37822
     51843 |   3747
     76418 |  51843
     17696 |   3947
     29287 |  17696
     41121 |  29287
     80429 |  41121
     93084 |  57724
     84640 |  93084
     96777 |  84640
     93091 |  96777
     45980 |  60532
     53891 |  43196
      5035 |   1871 */

 


