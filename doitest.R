library("rAltmetric")
library("plyr")
library("dplyr")
library("tidyr")
library("ggplot2")
library("forcats")

# provide a list of the dois of articles to get altmetrics for
dois <- c("10.1002/prca.201400084","10.1007/978-94-011-0904-8_20","10.1007/s12560-013-9133-1","10.1007/s40258-016-0243-4","10.1038/nrclinonc.2016.217","10.1038/nrgastro.2014.235","10.1038/nrneph.2013.282","10.1071/WR08060","10.1080/03043797.2014.895704","10.1080/09523367.2014.958666","10.1080/106836021000034997","10.1080/10824669.2012.636728","10.1080/14616688.2016.1214977","10.1080/15562948.2013.848007","10.1080/17439884.2014.933847","10.1081/LFT-100105278","10.1093/jeg/2.1.31","10.1097/MLR.0000000000000112","10.1097/PSY.0b013e318148c19a","10.1111/j.1365-2907.1986.tb00036.x","10.1163/156856294x00347","10.1353/jnc.2015.0009","10.1517/14656566.2015.981524","10.1524/zkri.216.8.417.20360","10.1680/mpal.13.00055","10.17660/ActaHortic.1985.169.26","10.3934/mbe.2010.7.195","10.4018/978-1-4666-5982-7.ch015","10.7763/IJCTE.2016.V8.1014")

# only return if there is data
getArticleData <- function(x) {
  print(x)
  articleData <- try(altmetrics(doi = x), silent = TRUE)
  if (class(articleData) == 'try-error') {
    return(NA)
  }
  articleData
}

na.omit.list <- function(y) { return(y[!sapply(y, function(x) all(is.na(x)))]) } # Removes NAs from list: https://gist.github.com/rhochreiter/7029236

raw_metrics <- lapply(dois, function(x) getArticleData(x))

raw_metrics <- na.omit.list(raw_metrics)

# get the raw_metrics data

metric_data <- ldply(raw_metrics, altmetric_data)

# include "cited_by_posts_count" if you want posts as well
columns_to_grab <- c("title", "doi", "url", "pmid", "journal", "cited_by_fbwalls_count", "cited_by_posts_count", "cited_by_feeds_count", "cited_by_gplus_count", "cited_by_msm_count", "cited_by_tweeters_count", "cited_by_accounts_count")

subset_data <- select(metric_data, one_of(columns_to_grab))

reshape_data <- subset_data %>%
  gather(cited_by, times, cited_by_fbwalls_count:cited_by_accounts_count) %>%
  mutate(cited_by = gsub("_count", "", cited_by)) %>%
  mutate(cited_by = gsub("cited_by_", "", cited_by)) %>%
  mutate(cited_by = gsub("tweeters", "Twitter", cited_by)) %>%
  mutate(cited_by = gsub("fbwalls", "Facebook", cited_by)) %>%
  mutate(cited_by = gsub("gplus", "Google+", cited_by)) %>%
  mutate(cited_by = gsub("feeds", "Bloggers", cited_by)) %>%
  mutate(cited_by = gsub("msm", "News Outlets", cited_by)) %>%
  mutate(cited_by = gsub("posts", "Posts", cited_by)) %>%
  mutate(cited_by = gsub("accounts", "Total", cited_by)) %>%
  mutate(times = as.numeric(times))

#filter the data by times cited to be greater than or equal to 4
graph_data <- reshape_data %>% 
  filter(times >= 4) %>%
  filter(cited_by != "Total")

#set a color-blind friendly color palette
cbPalette <- c("#333333", "#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7")

#graph the data
ggplot(graph_data) + geom_bar(aes(fct_infreq(factor(cited_by)), times, fill=doi), stat="identity") + labs(x = "Media") + scale_fill_manual(values=cbPalette) + theme_classic()

#write the data to csv
write.csv(metric_data, file = 'sample_data_altmetrics.csv')
