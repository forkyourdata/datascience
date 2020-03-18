library(RSQLite)
library(DBI)
library(ggplot2)

run_query <- function(query){
  conn <- dbConnect(SQLite(),'chinook.db')
  result <- dbGetQuery(conn, query)
  dbDisconnect(conn)
  return(result)
}

show_tables <- function(){
  query <- "SELECT
              name,
              type
            FROM sqlite_master
            WHERE type IN('table', 'view');"
  return(run_query(query))
}

show_tables()



query2 <- "SELECT 
                  g.name genre, 
                  SUM(il.quantity) genre_sales_rate, 
                  CAST(SUM(il.quantity) as Float) / (SELECT 
                                                            COUNT(*) 
                                                     FROM customer c
                                                     INNER JOIN invoice i ON i.customer_id = c.customer_id
                                                     INNER JOIN invoice_line il ON il.invoice_id = i.invoice_id                                                     
                                                     WHERE country = 'USA'
                                                     ) genre_sales_per
           FROM customer c
           INNER JOIN invoice i ON i.customer_id = c.customer_id
           INNER JOIN invoice_line il ON il.invoice_id = i.invoice_id
           INNER JOIN track t ON t.track_id = il.track_id
           INNER JOIN genre g ON g.genre_id = t.genre_id
           WHERE country = 'USA'
           GROUP BY 1
           ORDER BY 2 DESC LIMIT 10;"                       
usa_genre_per <- run_query(query2)

ggplot(data = usa_genre_per) + aes(x = genre, y = genre_sales_per) +
  geom_bar(stat = "identity")+ ylim(0,0.8) + theme(panel.background = element_rect('white'))

#Suppose your store associates have recommended 
#albums from Regal (hip-hop), Red Tone (punk), Metor and the Girls (pop), 
#and Slim Jim Bites (blues), and you want a more popular genre. 
#The graph of the five best-selling genres in the United States includes punk and blues.

query3 <- "WITH customer_total AS
                (
                 SELECT c.customer_id, 
                        c.support_rep_id, 
                        SUM(i.total) total
                 FROM customer c
                 INNER JOIN invoice i ON i.customer_id = c.customer_id
                 GROUP BY 1
                 )
           SELECT 
                 e.first_name || ' ' || e.last_name employee_name,
                 e.title,
                 SUM(ct.total) total_sales
          FROM employee e
          INNER JOIN customer_total ct ON ct.support_rep_id = e.employee_id
          GROUP BY 1;"

employee_total_sales <- run_query(query3)

ggplot(data = employee_total_sales) + aes(x = employee_name, y = total_sales) + geom_bar(stat = 'identity')



country_sales <- "WITH customer_info AS
                         (
                          SELECT COUNT(distinct(c.customer_id)) customers, 
                                 CASE
                                     WHEN (SELECT 
                                                 COUNT(*) 
                                           FROM customer 
                                           WHERE country = c.country 
                                           GROUP BY country) = 1
                                     THEN 'other'
                                 ELSE c.country
                                 END AS country_group,  
                                 SUM(i.total) total,
                                 COUNT(distinct(i.invoice_id)) invoice_count
                          FROM customer c
                          INNER JOIN invoice i ON i.customer_id = c.customer_id
                          GROUP BY country_group
                         )
                     SELECT country_group,
                            CASE
                                WHEN country_group = 'other' THEN 1
                            ELSE 0
                            END AS is_other,
                            customers,
                            total,
                            ROUND(total / customers, 2) avg_customers_sales, 
                            ROUND(total / invoice_count, 2) avg_order_sales 
                     FROM customer_info
                     ORDER BY is_other, total DESC;"

country_sales_info <- run_query(country_sales)
country_sales_info

ggplot(data = country_sales_info) +
  aes(x = country_group, y = customers, fill = country_group) +
  geom_bar(stat = 'identity') +
  labs(x = "Country", y = "number of customers")

ggplot(data = country_sales_info) +
  aes(x = country_group, y = total, fill = country_group) +
  geom_bar(stat = 'identity', width = 0.6) +
  labs(x = "Country", y = "Total")

ggplot(data = country_sales_info) +
  aes(x = country_group, y = avg_customers_sales, fill = country_group) +
  geom_bar(stat = 'identity', width = 0.6) +
  labs(x = "Country", y = "Average Customers Sales")

ggplot(data = country_sales_info) +
  aes(x = country_group, y = avg_order_sales, fill = country_group) +
  geom_bar(stat = 'identity', width = 0.6) +
  labs(x = "Country", y = "Average Order Sales")

#Although the United States has a large number of customers and a total amount of money, 
#the Czech Republic has a high average price per customer and a high average price per order, 
#so I think there will be more opportunities if you have customers in the Czech Republic.

#album_or_track <- "WITH invoice_album_track AS
#                      (
#                       SELECT 
#                             il.invoice_id invoice_id, 
#                             al.album_id album_id, 
#                             COUNT(t.track_id) num_tracks
#                       FROM invoice_line il
#                       INNER JOIN track t ON t.track_id = il.track_id
#                       INNER JOIN album al ON al.album_id = t.album_id
#                       GROUP BY 1,2
#                       ORDER BY 1,2
#                       )
#                       SELECT
#                             album_purchase_or_not,    
#                             COUNT(DISTINCT(invoice_id)) number_of_invoice,
#                             CAST(COUNT(DISTINCT(invoice_id)) as Float) / (SELECT COUNT(*) FROM invoice) percent
#                       FROM (SELECT 
#                                  iat.*, t_num_tracks,
#                                  CASE 
#                                      WHEN num_tracks != 1 AND num_tracks = t_num_tracks THEN 'yes'
#                                      ELSE 'no' 
#                                  END AS album_purchase_or_not 
#                             FROM invoice_album_track iat
#                             INNER JOIN (
#                                          SELECT 
#                                                album_id t_album_id, 
#                                                COUNT(t.track_id) t_num_tracks 
#                                          FROM track t
#                                          GROUP BY album_id
#                                          ) all_num_tracks ON 
#                                          all_num_tracks.t_album_id = iat.album_id)
#                      GROUP BY album_purchase_or_not;"
#run_query(album_or_track)
#  album_purchase_or_not number_of_invoice   percent
#1                    no               503 0.8192182
#2                   yes               111 0.1807818

####This is definitely a problem. This is because there is a single album with only one track.


album_or_track <- "WITH invoice_first_track AS
                   (
                    SELECT
                    il.invoice_id invoice_id,
                    MIN(il.track_id) first_track_id
                    FROM invoice_line il
                    GROUP BY 1
                    )
                    
                    SELECT
                    album_purchase,
                    COUNT(invoice_id) number_of_invoices,
                    CAST(count(invoice_id) AS FLOAT) / (
                    SELECT COUNT(*) FROM invoice
                    ) percent
                    FROM
                    (
                      SELECT
                      ifs.*,
                      CASE
                      WHEN
                      (
                      SELECT t.track_id FROM track t
                      WHERE t.album_id = (
                      SELECT t2.album_id FROM track t2
                      WHERE t2.track_id = ifs.first_track_id
                      ) 
                      
                      EXCEPT 
                      
                      SELECT il2.track_id FROM invoice_line il2
                      WHERE il2.invoice_id = ifs.invoice_id
                      ) IS NULL
                      AND
                      (
                      SELECT il2.track_id FROM invoice_line il2
                      WHERE il2.invoice_id = ifs.invoice_id
                      
                      EXCEPT 
                      
                      SELECT t.track_id FROM track t
                      WHERE t.album_id = (
                      SELECT t2.album_id FROM track t2
                      WHERE t2.track_id = ifs.first_track_id
                      ) 
                      ) IS NULL
                      THEN 'yes'
                      ELSE 'no'
                      END AS 'album_purchase'
                      FROM invoice_first_track ifs
                    )
                    GROUP BY album_purchase;"

run_query(album_or_track)

#The album purchase was only 18.6%. Buying a track is a better choice.
