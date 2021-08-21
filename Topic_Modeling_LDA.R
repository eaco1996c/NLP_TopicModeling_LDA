knitr::opts_chunk$set(echo =FALSE)
library(ggplot2)
library(tidytext)
library(tidyverse)
library(stm)
library(topicmodels)
library(stringi)
library(gutenbergr)
library(wordcloud)
library(janitor)
library(tidytext)
library(gutenbergr)
library(janeaustenr)
library(scales)
library(dplyr)



# Section 1
## Import full_collection
full_collection <- gutenberg_download(c(219,43,844,4300),
                                      meta_fields = "title")
head(full_collection)
## Tidy data
tidy <- full_collection %>%unnest_tokens(word, text)
head(tidy)
## Remove stop words
tidy <- tidy%>% anti_join(get_stopwords(source ="smart"))
head(tidy)
## Top 20 common words
tidy%>%
  count(word,sort =TRUE)%>%top_n(20)%>%
  ggplot(aes(fct_reorder(word,n), n))+
  geom_col()+coord_flip()



# Section 2
## Download data by author
full_collection_author <- gutenberg_download(c(219,43,844,4300),
                                      meta_fields = "author")
full_collection_author %>% count(author)

conrad_joseph <-  gutenberg_download(c(219))%>%unnest_tokens(word, text)%>%anti_join(get_stopwords(source ="smart"))
conrad_joseph %>%
  count(word,sort = TRUE)

Stevenson_RobertLouis<- gutenberg_download(c(43))%>%unnest_tokens(word, text)%>%anti_join(get_stopwords(source ="smart"))
Stevenson_RobertLouis %>% 
  count(word,sort = TRUE)

Wilde_Oscar <-gutenberg_download(c(844))%>%unnest_tokens(word, text)%>%anti_join(get_stopwords(source ="smart"))
Wilde_Oscar %>%
  count(word,sort = TRUE)

Joyce_James <-gutenberg_download(c(4300))%>%unnest_tokens(word, text)%>%anti_join(get_stopwords(source ="smart"))
Joyce_James %>%
  count(word,sort = TRUE)


book_topics <- chapter_classifications %>%
  count(title, topic) %>%
  top_n(1, n) %>%
  ungroup() %>%
  transmute(consensus = title, topic)

book_topics

## bind_rows function
tidy_book <- bind_rows(mutate(conrad_joseph,author ="Conrad Joseph"),
                       mutate(Stevenson_RobertLouis,author ="Stevenson"),
                       mutate(Wilde_Oscar,author ="Wilde Oscar"),
                       mutate(Joyce_James,author = "Joyce James")) %>% 
mutate(word =str_extract(word,"[:alpha:]+"))%>%
count(author, word,sort = TRUE) 

head(tidy_book)  
  
frequency <- tidy_book %>% add_count(author, wt = n, name = "total_word")%>%  
mutate(proportion = n / total_word) %>%
select(-total_word, -n) %>%
pivot_wider(names_from = author, values_from = proportion, 
              values_fill = list(proportion = 0))%>%
pivot_longer(3:5, names_to = "author", values_to = "proportion")

frequency
class(frequency)
dim(frequency)
names(frequency)
tabyl(frequency$author)

library(scales)

## Frequency plots
ggplot(frequency,aes(x=proportion,y=`Joyce James`,color = abs(`Joyce James`-proportion)))+
             geom_abline(color ="gray40",lty =2)+
     geom_jitter(alpha =0.1,size =2.5,width =0.3,height =0.3)+
  geom_text(aes(label =word),check_overlap =TRUE,vjust =1.5) +
  scale_x_log10(labels =percent_format())+scale_y_log10(labels =percent_format())+
  scale_color_gradient(limits =c(0,0.001),low ="darkslategray4",high ="gray75")+
  facet_wrap(~author,ncol =2)+theme(legend.position ="none")+labs(y="Joyce James",x=NULL)

##  Correlation computing
cor.test(data =frequency[frequency$author=="Conrad Joseph",],~proportion+`Joyce James`)

cor.test(data =frequency[frequency$author=="Stevenson",],~proportion+`Joyce James`)

cor.test(data =frequency[frequency$author=="Wilde Oscar",],~proportion+`Joyce James`)


##  Sentiment analysis
tidy_james <- Joyce_James  %>% mutate(Joyce_James,author = "Joyce James")
senti_james<- tidy_james%>% 
   inner_join(get_sentiments("bing"))%>%
   count(word, sentiment, sort = TRUE)%>%
  ungroup()
senti_james
senti_james%>% group_by(sentiment)%>% 
  top_n(10)%>% ungroup()%>%
  mutate(word =reorder(word, n))%>%
  ggplot(aes(n, word, fill = sentiment))+
  geom_col(show.legend = FALSE)+ facet_wrap(~sentiment, scales = "free_y")+
  labs(x = "Count", y = NULL)

# Section 3
## Calculate the tf_idf for all the tokens in the combined dataset
book_tf_idf <-tidy_book%>%bind_tf_idf(word, author, n)
book_tf_idf
book_tf_idf %>%
  slice_max(tf_idf,n=10)
library(forcats)

book_tf_idf%>%group_by(author)%>%
  slice_max(tf_idf,n=10)%>%
  ungroup()%>%
  ggplot(aes(tf_idf,fct_reorder(word, tf_idf),fill =author))+
  geom_col(show.legend =FALSE)+
  facet_wrap(~author,ncol =2,scales ="free")+
  labs(x="tf-idf",y=NULL)

## Plot the tf_idf for each book by titles
tidy_title <- full_collection %>%
  unnest_tokens(word,text) %>%
  count(title,word,sort = TRUE)
book_tf_idf_title <-tidy_title%>%bind_tf_idf(word, title, n)

book_tf_idf_title%>%group_by(title)%>%
  slice_max(tf_idf,n=10)%>%
  ungroup()%>%
  ggplot(aes(tf_idf,fct_reorder(word, tf_idf),fill =title))+
  geom_col(show.legend =FALSE)+
  facet_wrap(~title,ncol =2,scales ="free")+
  labs(x="tf-idf",y=NULL)

same <- c("snag","grass","bush","big")
subset(book_tf_idf_title,word %in% same, title = "Heart of Darkness")







# Final Topic Modeling
## 1. Data Retrievement and cleanse
books <- gutenberg_download(c(164,36,768), meta_fields = 'title')
books
dim(books)

by_chapter <- books%>% group_by(title)%>% 
  mutate(chapter =cumsum(str_detect(text,regex("^chapter ", ignore_case = TRUE))))%>%
  ungroup()%>%filter(chapter>0)%>% 
  unite(document, title, chapter)

head(by_chapter)

head(by_chapter)

by_chapter_word <- by_chapter%>% unnest_tokens(word, text)
dim(by_chapter_word)

word_counts <- by_chapter_word%>% anti_join(get_stopwords())%>%
count(document, word, sort = TRUE)%>% ungroup()

glimpse(word_counts)

## 2. LDA
### 2.1
chapters_dtm <- word_counts%>% cast_dtm(document, word, n)
chapters_dtm
### 2.2
chapters_lda <-LDA(chapters_dtm, k = 3, control =list(seed = 1234))
chapters_lda

chapter_topics <-tidy(chapters_lda, matrix = "beta")
chapter_topics

### 2.3
top_terms <- chapter_topics%>% group_by(topic)%>% top_n(5,beta)%>% ungroup()%>% arrange(topic,-beta)
top_terms

top_terms%>% mutate(term =reorder_within(term, beta, topic))%>%
  ggplot(aes(beta, term, fill =factor(topic)))+ 
  geom_col(show.legend = FALSE)+facet_wrap(~topic, scales = "free")+
  scale_y_reordered()
### 2.4
chapters_gamma

chapters_gamma <-tidy(chapters_lda, matrix = "gamma")

chapters_gamma <- chapters_gamma%>% separate(document,c("title","chapter"), sep = "_", convert = TRUE)

chapters_gamma%>% mutate(title =reorder(title, gamma*topic))%>%
  ggplot(aes(factor(topic), gamma))+ 
  geom_boxplot()+ facet_wrap(~title)+
  labs(x = "topic", y =expression(gamma))


### 2.5
chapter_classifications <- chapters_gamma%>% 
  group_by(title,chapter)%>% 
  slice_max(gamma)%>%ungroup()

chapter_classifications %>% knitr::kable()


book_topics <- chapter_classifications%>% 
  count(title, topic)%>%
  group_by(title)%>% 
  top_n(1, n)%>% ungroup()%>% 
  transmute(consensus = title,topic)
book_topics

join<- chapter_classifications %>%
  inner_join( book_topics, by = 'topic') 


join[which(join$title!= join$consensus),]


chapter_classifications
chapter_classifications[which(chapter_classifications$topic == 1),]
chapter_classifications[which(chapter_classifications$topic == 2),]
chapter_classifications[which(chapter_classifications$topic == 3),]






assignments <-augment(chapters_lda, data = chapters_dtm)
assignments

assignments <- assignments%>% 
  separate(document,c("title","chapter"), sep = "_", convert = TRUE)%>% 
  inner_join(book_topics,by =c(.topic = "topic"))

assignments
topic1 <- assignments[which(assignments$.topic == 1),] 
topic2<- assignments[which(assignments$.topic == 2),] 
topic3<- assignments[which(assignments$.topic == 3),] 
dim(topic1)
dim(topic2)
dim(topic3)

assignments %>% filter(title!=consensus)
# each topic's consensus development
topic1 <- topic1 %>% filter(title!=consensus)
topic2 <-topic2 %>% filter(title!=consensus)
topic3 <- topic3 %>% filter(title!=consensus)

topic1%>%knitr::kable()



#### Confusion Matrix
assignments %>%
  count(title, consensus, wt = count) %>%
  spread(consensus, n, fill = 0) %>%
  knitr::kable()

library(knitr)


assignments%>% count(title, consensus, wt = count)%>% 
  mutate(across(c(title,consensus),~str_wrap(., 20)))%>% 
  group_by(title)%>% mutate(percent = n/sum(n))%>%
  ggplot(aes(consensus, title, fill = percent))+ 
  geom_tile()+scale_fill_gradient2(high = "darkred", label =percent_format())+theme_minimal()+ 
  theme(axis.text.x =element_text(angle = 90,hjust = 1), panel.grid =element_blank())+ 
  labs(x = "Book words were assigned to",y = "Book words came from", fill = "% of assignments")


### 2.6 Take the chapters_gamma dataframe and group it by title and chapter and then use the slice_max function 
#### selects the rows with the highest values of the gamma variable.

gamma_max <- chapters_gamma%>% 
  group_by(title,chapter)%>% 
  slice_max(gamma)

gamma_max

ggplot(chapters_gamma, aes(gamma, fill = factor(topic))) +
  geom_histogram() +
  facet_wrap(~ title, nrow = 2)

chapter_classifications %>%
  inner_join(book_topics, by = "topic") %>%
  count(title, consensus) %>%
  knitr::kable()


### 2.7 Develop the ¡°consensus¡± topic for each book



wrong_words <- assignments%>% filter(title!=consensus)
wrong_words
wrong_words%>% count(title, consensus, term, wt = count)%>%ungroup()%>% arrange(desc(n))
#### wrong word search
word_counts%>% filter(word=="flopson")

words_sparse <- word_counts%>% cast_sparse(document, word, n)



library(stm)
topic_model <-stm(words_sparse, K = 3,verbose = FALSE,init.type = "Spectral")
summary(topic_model)

chapter_topics <-tidy(topic_model, matrix = "beta")
chapter_topics

chapters_gamma_stm <-tidy(topic_model, matrix = "gamma", document_names =rownames(words_sparse))
chapters_parsed_stm <- chapters_gamma_stm%>% separate(document,c("title", "chapter"), sep = "_", convert = TRUE)
chapters_parsed_stm%>% mutate(title =fct_reorder(title, gamma*topic))%>% ggplot(aes(factor(topic), gamma))+
  geom_boxplot()+
facet_wrap(~title)

library(furrr)
install.packages('furrr')

plan(multicore)
many_models <-tibble(K =c(3, 4, 6, 8, 10))%>% 
  mutate(topic_model =future_map(K,seed = TRUE,~stm(words_sparse, K = ., verbose = FALSE)))




misclassifications <-  chapter_classifications %>% 
  inner_join(book_topics, by = "topic") %>%
  filter(title != consensus)
misclassifications


### 2.8 Use the augment function to develop the words assignment for each topic
assignments <-augment(chapters_lda, data = chapters_dtm)

assignments <- assignments%>% 
  separate(document,c("title","chapter"), sep = "_", convert = TRUE)%>% 
  inner_join(book_topics,by =c(.topic = "topic"))

assignments
assignments[which(assignments$.topic == 1),] 
assignments[which(assignments$.topic == 2),] 
assignments[which(assignments$.topic == 3),] 



### 2.9 Develop the confusion matrix for all the topics
#### Confusion Matrix
assignments %>%
  count(title, consensus, wt = count) %>%
  spread(consensus, n, fill = 0) %>%
  knitr::kable()
