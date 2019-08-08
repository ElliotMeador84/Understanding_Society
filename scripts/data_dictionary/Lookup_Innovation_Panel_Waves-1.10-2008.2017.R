library(tidyverse) # all things tidy

## Uses data from this file

# source('scripts/data_dictionary/Dictionary_Innovation_Panel_Waves-1.10-2008.2017.R')

# get directory of file names


data_file_names <-
    dir('data/Innovation_Panel_Waves-1.10-2008.2017/UKDA-6849-tab/tab',
        full.names = T)


# map the dataframe names to each file
file_base_names <- map(data_file_names, basename) %>%
    str_remove_all('.tab$')


# read files
data_files_ls <- map(data_file_names, function(x) {
    read_delim(x,
               "\t",
               escape_double = FALSE,
               trim_ws = TRUE)
}) %>%
    set_names(file_base_names)



# Comment a brief explanation of what the file contains.
comment(data_files_ls) <-
    'List of tibbles containing Innovation_Panel_Waves-1.10-2008.2017/UKDA-6849-tab files.'

# Save the file as an R data object, .RData.
save(data_files_ls,
     file = 'data/data_files_ls.RData')


#######################################
## Stats comparing size of databases ##
#######################################


# some files are over 2,000 variables long

dir.create('png/file_size')

file_length_gg <- data_files_ls %>%
    map_dbl(length) %>%
    as_tibble() %>%
    ggplot(aes(value)) +
    geom_density(fill = 'forestgreen') +
    theme_minimal() +
    scale_x_continuous(labels = scales::comma) +
    labs(x = 'Number of variables in dataset',
         title = 'File length of Understanding Society download')


ggsave(file_length_gg, 
       width = 6, 
       height = 5, 
       filename = 'png/file_size/file_length_gg.png')


# One file has over 90,000 rows in it.
file_nrow_gg <- data_files_ls %>%
    map_dbl(nrow) %>%
    as_tibble() %>%
    ggplot(aes(value)) +
    geom_density(fill = 'skyblue') +
    theme_minimal() +
    scale_x_continuous(labels = scales::comma) +
    labs(x = 'Number of respodents in dataset',
         title = 'Number of rows in each file of Understanding Society download')


ggsave(file_nrow_gg, 
       width = 6, 
       height = 5, 
       filename = 'png/file_size/file_nrow_gg.png')



file_length <- data_files_ls %>%
    map_dbl(length)

file_rows <- data_files_ls %>%
    map_dbl(nrow)

# Scatterplot of # variables and length

nrow_length_scatter_gg <- tibble(x = file_rows,
       y = file_length) %>%
    ggplot(aes(x, y)) +
    geom_smooth(color = 'tomato') +
    geom_point(color = 'tomato3',
               size = 3) +
    labs(x = '# rows',
         y = '# variables',
         title = 'Generally, datasets with more variables have more rows\n (for datasets under 1,000 variables and rows)') +
    scale_x_log10(labels = scales::comma) +
    scale_y_log10(labels = scales::comma) +
    theme_minimal()


ggsave(nrow_length_scatter_gg, 
       width = 6, 
       height = 5, 
       filename = 'png/file_size/nrow_length_scatter_gg.png')


# dataset detailing file names and variables for look-up


data_file_lookup <- map2_df(data_files_ls,
     file_base_names,
     function(x, y) {
         names(x) %>%
             as_tibble() %>%
             mutate(file_name = rep(y, nrow(.))) %>%
             select(file_name, variable = value)
             
     })

# This file can be merged with the data dictionary to make the look-up file more comprehensive

load('data/UK_understanding_society_data_dictionary.RData')


# merge with data dictionary -- only variable and description
UK_understanding_society_data_look_up <- 
    data_file_lookup %>% 
    left_join(
    
UK_understanding_society_data_dictionary %>% 
    select(variable, 
           description)
) %>% 
    distinct()
    
    
# add a comment attribute briefly describing the database. 
comment(UK_understanding_society_data_look_up) <- 
    c('File contains the variables and variable-descriptions for each file in the UK Understanding Society Innovation_Panel_Waves-1.10-2008.2017 download.',
         'Derived from the /Innovation_Panel_Waves-1.10-2008.2017/UKDA-6849-tab/mrdoc/allissue/ directory of the UK Understanding Society download. Compilation occured on 2019-08-07.')
    
    
save(UK_understanding_society_data_look_up, 
     file = 'data/UK_understanding_society_data_look_up.RData',
     compress = T)    
    
    
UK_understanding_society_data_look_up %>% 
    write_csv('data/UK_understanding_society_data_look_up.csv')






