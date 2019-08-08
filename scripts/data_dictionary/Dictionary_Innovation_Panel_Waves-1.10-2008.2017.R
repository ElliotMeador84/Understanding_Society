library(tidyverse) # all things tidy
library(striprtf) # reading .rtf files
library(naniar) # dealing with NA's






###############################################
#### Understanding Society Data Dictionary ####
###############################################




# Read data dictionary from .rtf file. .rtf is a like a Microsoft word file.


## This dplyr-function will tidy the .rtf files into a stackeble dataframe 

parse_dictionary <- function(x){
    x %>% 
        as_tibble() %>% 
        slice(12:nrow(.)) %>% 
        mutate(position = case_when(
            str_detect(value, '^Pos.') ~ 1, T~0), 
            type = case_when(
                str_detect(value, 'SCALE') ~ 'scale', 
                str_detect(value, 'NOMINAL') ~ 'nominal', 
                str_detect(value, 'ORDINAL') ~ 'ordinal', 
                T~NA_character_), 
            type = lead(type)) %>% 
        fill(type) %>% 
        mutate(meta = value) %>% 
        separate(meta, c('position', 'variable', 'label'), sep = '\\t', remove = F) %>% 
        mutate(position = str_remove_all(position, 'Pos. = '), 
               variable = str_remove_all(variable, 'Variable = '), 
               label = str_remove_all(label, 'Variable label = ')) %>% 
        mutate_at(vars(position, variable, label), list(~str_squish(str_trim(.)))) %>% 
        mutate(position = parse_number(position)) %>% 
        select(-value, -meta) %>% 
        mutate(value = variable, 
               value = parse_number(value), 
               description = label, 
               description = case_when(str_detect(description, 'Label =')~'', T~description), 
               label = case_when(str_detect(label, 'Label =')~label, T~''),
               label = str_remove_all(label, 'Label = '),
               variable = case_when(str_detect(variable, 'Value')~'', T~variable)) %>% 
        replace_with_na(list(description = '', variable = '')) %>%
        fill(variable, description, .direction = 'down') %>%
        drop_na(variable)  
}


dictionary_file_names <- dir('data/Innovation_Panel_Waves-1.10-2008.2017/UKDA-6849-tab/mrdoc/allissue', 
                             full.names = T)


# pull sizes of each file to break up the process (it is time consuming)

dictionary_size_df <- map_dbl(dictionary_file_names, function(x){
    file.info(x)$size}) %>% 
    as_tibble() %>% 
    mutate(id = row_number())


 # split on size to break up file reading
 
dictionary_size_ls <- dictionary_size_df %>% 
    mutate(cut = dplyr::cume_dist(value), 
           quin = 
               case_when(
                   between(cut, 0, .25) ~ 'smallest',
                   between(cut, 0.2501, .5) ~ 'small',
                   between(cut, 0.501, .75) ~ 'large',
                   T~'largest'), 
           quin = factor(quin, levels = c('smallest', 
                                             'small', 
                                             'large', 
                                             'largest'))) %>% 
    split(.$quin) 


size_rank_index <- map(dictionary_size_ls, function(x){
        x %>% 
            pull(id)
        })


## cut files into ranking order

  
dictionary_file_ranks_ls <- map(size_rank_index, function(x){
    dictionary_file_names[x]
})


## (Should technically loop these as there's more than 3 iterations)


# smallest files
smallest_ls <- map(dictionary_file_ranks_ls$smallest, 
           possibly(function(x){
    read_rtf(x)
}, NULL))


smallest_df <- map_df(smallest_ls,parse_dictionary)


# small files
small_ls <- map(dictionary_file_ranks_ls$small, 
                   possibly(function(x){
                       read_rtf(x)
                   }, NULL))

small_df <- map_df(small_ls,parse_dictionary)


# large files
large_ls <- map(dictionary_file_ranks_ls$large, 
                possibly(function(x){
                    read_rtf(x)
                }, NULL))

large_df <- map_df(large_ls,parse_dictionary)


# largest files
largest_ls <- map(dictionary_file_ranks_ls$largest, 
                possibly(function(x){
                    read_rtf(x)
                }, NULL))

largest_df <- map_df(largest_ls,parse_dictionary)




# Bind all files

UK_understanding_society_data_dictionary <- bind_rows(smallest_df, small_df, large_df, largest_df)


 # add a comment attribute briefly describing the database. 
 # 
comment(UK_understanding_society_data_dictionary) <- 
    c('Derived from the /Innovation_Panel_Waves-1.10-2008.2017/UKDA-6849-tab/mrdoc/allissue/ directory of the UK Understanding Society download. Compilation occured on 2019-08-07.')


 # Save as .RData 
save(UK_understanding_society_data_dictionary, file = 'data/UK_understanding_society_data_dictionary.RData', compress = T)


# Write to .csv
UK_understanding_society_data_dictionary %>% 
    write_csv('data/UK_Understanding_Society_Data_Dictionary.csv')













