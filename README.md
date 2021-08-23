# NLP_TopicModeling_LDA
This a NLP course practice project with R. The main purpose is to utilizing Topic Modeling across three well-known novels, _Twenty Thousand Leagues under the Sea_,
_The War of the Worlds_, _Wuthering Heights_. 

First create the document term matrix (DTM). Then use **[LDA](https://medium.datadriveninvestor.com/nlp-with-lda-analyzing-topics-in-the-enron-email-dataset-20326b7ae36f)**(Latent Dirichlet Allocation) to make a 3-topic model. We are going to judge which two books are more closely related. 
- Separate the document name into title and chapter using the separate function and ggplot2 to visualize the per-document-per-topic probability for each topic
- Develop the “consensus” topic for each book
- Use the augment function to develop the words assignment for each topic
- Develop the confusion matrix for all the topics

**Project Framework**


## Data Sourcing

Using the command ‘gutenberg_download’ to access novels from gutenberg library with IDs:

_Twenty Thousand Leagues under the Sea_ ID: 164 | _The War of the Worlds_ ID: 36 | _Wuthering Heights_ ID: 768

Tidy tokenized data preprocee and create the document term matrix (DTM) by Chapter:

![image](https://user-images.githubusercontent.com/38795845/130508476-f5f9de3c-29b1-4ac1-bee2-eae858ed0c7d.png)

![image](https://user-images.githubusercontent.com/38795845/130508669-80effd53-e792-404b-ac62-4203cabf8475.png)

Info of the DTM:

![image](https://user-images.githubusercontent.com/38795845/130508754-025e7501-7daf-4a25-97d6-6aed3a7da6af.png)


## LDA Model

![image](https://user-images.githubusercontent.com/38795845/130508852-43e57146-a48b-4afc-8f25-adb7364f4b04.png)

### Top terms analysis

Use `dplyr’s top_n()` or `slice_max( )` function to find the top 5 terms within each
topic and subsequently use `ggplot2` to do a visualization.

![image](https://user-images.githubusercontent.com/38795845/130508998-9973f378-2bd5-4f1c-88a6-6581cda5218c.png)

Gamma value analysis between novels:

![image](https://user-images.githubusercontent.com/38795845/130509103-ef33988c-893f-475a-aa68-4c72d2c19ad6.png)
![image](https://user-images.githubusercontent.com/38795845/130509122-89ebf813-4217-47d2-ac21-df1616dacd2b.png)
![image](https://user-images.githubusercontent.com/38795845/130509135-80b14ff8-6106-4b95-b095-624e3e90df00.png)

Showing in the plot below, it can be concluded that the topic 1 and 2 having the
same highest gamma values, which means they are closest in association.



### “consensus” topic for each book
Tables below show the terms
assigned incorrectly to their former title. Book 1 The War of the Worlds(WOW)
has least wrong assignment,with only 5 into Wuthering Heights(WH) and 4 into
TTLS. Book2 has 6 wrong assignments into TTLS. And TTLS has 520 wrong
assignments to WOW.

![image](https://user-images.githubusercontent.com/38795845/130509474-fe36034d-089c-4052-9abe-aae38076d6d5.png)

![image](https://user-images.githubusercontent.com/38795845/130509488-c203b300-e49e-4a83-ae86-09695cc443fe.png)

![image](https://user-images.githubusercontent.com/38795845/130509522-56fa0243-f207-40b4-a550-35495add84cf.png)

**Per-document-per-topic confusion matrix of LDA model for each topic**

![image](https://user-images.githubusercontent.com/38795845/130509252-c3d30031-bf5b-48b5-9c44-af6ba721a0c6.png)


### The confusion matrix for all the topics with numbers

![image](https://user-images.githubusercontent.com/38795845/130509681-195f26cd-3ee9-4d10-8551-5817c857044a.png)

