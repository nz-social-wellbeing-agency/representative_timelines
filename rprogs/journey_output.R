#####################################################################################################
#' Description: Command script for producing Journey Timelines Output
#'
#' Input: SQL table produced by journey_timelines.R
#'
#' Output: 
#' 
#' Author: Simon Anastasiadis
#' 
#' Dependencies:
#' - utility_functions.R
#' - journey_output_functions.R
#' 
#' Notes: 5 minutes development mode, 2 hours non-development mode runtimes
#' 
#' Issues:
#' 
#' History (reverse order):
#' 2019-01-17 SA v0
#####################################################################################################

## source ----
setwd(paste0("~/Network-Shares/DataLabNas/MAA/MAA2016-15 Supporting the Social Investment Unit/",
             "Journey timelines - HaBiSA/rprogs"))
source('utility_functions.R')
source('journey_output_functions.R')
library(tidyr)
library(data.table)

## parameters ----

# user controls
DEVELOPMENT_MODE = FALSE
CAUTIOUS_MODE = TRUE
SINGLE_LARGE_AREA_MODE = FALSE
# cluster settings
NUMBER_OF_CLUSTERS = 12 # number of algorithmic clusters to produce
NUMBER_OF_BATCHES = 25 # number of batches to use, metaclustering then clusters (num-cluster * num-batch records)
SEQUENCE_CHANNEL_BATCH_SIZE = 6 # to speed up seqdistmc in sequence_collection_to_distances
CLUSTER_PLOT = TRUE # whether or not to plot meta clustering results

# input tables
EVENT_TABLE = "jt_event_locations"
# EVENT_TABLE = "jt_event_locations_AKL"
# EVENT_TABLE = "jt_event_locations_NZ"

GATHERED_DATA_TABLE = "jt_intersect_union_full"
# GATHERED_DATA_TABLE = "jt_intersect_union_AKL"
# GATHERED_DATA_TABLE = "jt_intersect_union_NZ"

# GATHERED_DATA_TABLE = "jt_intersect_union"

# other
INPUT_COLUMNS = c("snz_uid", "role", "event_id", "stage_name", "time_unit", "time",
                  "description", "value", "source")
OUTPUT_COLUMNS = c("group", "group_size", "role", "stage_name", "time_unit", "time",
                   "description", "source", "value")
TIMELINE_COLUMNS = c("-20", "-19", "-18", "-17", "-16", "-15", "-14", "-13", "-12", "-11", "-10",
                     "-9", "-8", "-7", "-6", "-5", "-4", "-3", "-2", "-1", "1", "2", "3", "4", "5",
                     "6", "7", "8", "9", "10", "11", "12", "13")

## setup ----

run_time_inform_user("---- GRAND START ----")
db_con_IDI_sandpit = create_database_connection(database = "IDI_Sandpit")
our_schema = "[IDI_Sandpit].[DL-MAA2016-15]"
our_views = "[IDI_UserCode].[DL-MAA2016-15]"

## load event tables ----

run_time_inform_user("create access points")

events = create_access_point(db_connection = db_con_IDI_sandpit,
                             schema =  our_views,
                             tbl_name = EVENT_TABLE,
                             db_hack = TRUE) %>%
  select(event_id, event_date)
 
required_columns = c("event_id", "event_date")
assert(table_contains_required_columns(events, required_columns, only = FALSE),
       msg = "event table does not contain all required columns")

if(DEVELOPMENT_MODE){
  events = events %>% filter(floor(event_id / 100) %% 100 == 0)
  NUMBER_OF_CLUSTERS = 5
  NUMBER_OF_BATCHES = 10
}

gathered_data = create_access_point(db_connection = db_con_IDI_sandpit,
                                    schema = our_schema,
                                    tbl_name = GATHERED_DATA_TABLE)
assert(table_contains_required_columns(gathered_data, INPUT_COLUMNS, only = FALSE),
       msg = "gathered data does not contain all required columns")

run_time_inform_user("load non-journey into R")

non_journey = gathered_data %>%
  filter(time_unit != "Fortnight") %>%
  inner_join(events, by = "event_id") %>%
  mutate(the_year = YEAR(event_date)) %>%
  collect()

run_time_inform_user("load journey into R")

journey = gathered_data %>%
  filter(time_unit == "Fortnight") %>%
  inner_join(events, by = "event_id") %>%
  mutate(the_year = YEAR(event_date)) %>%
  collect()

# ad hoc adjustment of birth weights to categorical
is_birth_weight = non_journey$description == 'BIRTH WEIGHT'
non_journey[is_birth_weight,"value"] = 200 * round(non_journey[is_birth_weight,"value"]  / 200, 0)

## collapse multiple siblings into single identity ----

siblings = journey %>%
  filter(role %in% c('full sibling', 'half sibling')) %>%
  group_by(role, event_id, stage_name, time_unit, time, description, source, the_year) %>%
  summarise(value = sum(value))

non_siblings = journey %>%
  filter(role %not_in% c('full sibling', 'half sibling')) %>%
  select(colnames(siblings))

journey_prepared = rbind(data.table(siblings),
                       data.table(non_siblings),
                       use.names = TRUE)

# remove unneeded & large datasets
# Commented for Testing - Uncommment after test execution - ACHOK001
# if(! DEVELOPMENT_MODE)
#   rm("siblings", "non_siblings", "journey")

## group pivot-journeys by clustering ----
# Integrating Michael's work

run_time_inform_user("clustering")

pivot_journey = journey_prepared %>%
  mutate(triplet = sprintf("%s-%s-%s",role,source,description)) %>%
  select(event_id, triplet, time, value) %>%
  mutate(value = pmin(value, 1)) %>%
  spread(time, value, fill = 0) %>%
  as.data.frame()

# events to cluster
events_to_cluster = pivot_journey %>% select(event_id) %>% unique()
# role, source, description triplets to cluster
triplets_to_cluster = pivot_journey %>% select(triplet) %>% unique()

if(!SINGLE_LARGE_AREA_MODE) {
  event_clusters = batch_processing(
    pivot_journey,
    "event_id",
    "triplet",
    channel_batch_size = SEQUENCE_CHANNEL_BATCH_SIZE,
    number_of_clusters = NUMBER_OF_CLUSTERS,
    give_plots = CLUSTER_PLOT,
    number_of_batches = NUMBER_OF_BATCHES
  )

  # convert medoids to text strings
  medoids = event_clusters %>% select(medoid) %>% unique()
  medoids = medoids %>% mutate(group_name = paste0("cluster ",1:nrow(medoids)))
  event_clusters = event_clusters %>%
    inner_join(medoids, by = "medoid") %>%
    select(event_id, group_name)
}

## group non-journeys by manual definition ----
run_time_inform_user("manual group definition")
#### parental groups ----
# mother or father previously sentenced
prev_sentence = non_journey %>%
  filter(role %in% c('mother', 'father'),
         stage_name == 'pre_post',
         time == -100,
         description %in% c('community sentence', 
                            'detained sentence',
                            'home detention sentence',
                            'under conditions', 
                            'under supervision')) %>%
  select(event_id) %>%
  unique() %>%
  mutate(group_name = "corrections_sentence")

# mother or father chronic condition
chronic_condition = non_journey %>%
  filter(role %in% c('mother', 'father'),
         stage_name == 'pre_post',
         time == 0,
         description == "chronic") %>%
  select(event_id) %>%
  unique() %>%
  mutate(group_name = "chronic_condition")

#Testing 
# write.csv(chronic_condition, file = "/home/STATSNZ/dl_achokkanat/Network-Shares/DataLabNas/MAA/MAA2016-15 Supporting the Social Investment Unit/Journey timelines - HaBiSA/rprogs/chronic.csv")

# migrants
new_migrants = non_journey %>%
  filter(role %in% c('mother', 'father'),
         stage_name == 'pre_post',
         time == -100,
         description == "migrant first arrival") %>%
  select(event_id) %>%
  unique() %>%
  mutate(group_name = "migrant")

#### ethnicity groups ----
# ethnicity = Asian
ethnic_asian = non_journey %>%
  filter(role %in% c('mother', 'father'),
         stage_name == 'pre_post',
         time == 0,
         description == "Ethnicity = ASIAN") %>%
  select(event_id) %>%
  unique() %>%
  mutate(group_name = "ethnic_asian")

# ethnicity = European
ethnic_european = non_journey %>%
  filter(role %in% c('mother', 'father'),
         stage_name == 'pre_post',
         time == 0,
         description == "Ethnicity = EUROPEAN") %>%
  select(event_id) %>%
  unique() %>%
  mutate(group_name = "ethnic_european")

# ethnicity = Maori
ethnic_maori = non_journey %>%
  filter(role %in% c('mother', 'father'),
         stage_name == 'pre_post',
         time == 0,
         description == "Ethnicity = MAORI") %>%
  select(event_id) %>%
  unique() %>%
  mutate(group_name = "ethnic_maori")

# ethnicity = Other
ethnic_other = non_journey %>%
  filter(role %in% c('mother', 'father'),
         stage_name == 'pre_post',
         time == 0,
         description == "Ethnicity = OTHER") %>%
  select(event_id) %>%
  unique() %>%
  mutate(group_name = "ethnic_other")

# ethnicity = Pacific
ethnic_pacific = non_journey %>%
  filter(role %in% c('mother', 'father'),
         stage_name == 'pre_post',
         time == 0,
         description == "Ethnicity = PACIFIC") %>%
  select(event_id) %>%
  unique() %>%
  mutate(group_name = "ethnic_pacific")

#### MHA groups ----
# alcohol and drug
alcohol_drug = non_journey %>%
  filter(role %in% c('mother', 'father'),
         stage_name == 'pre_post',
         time == 0,
         description == "program with alcohol and drug team") %>%
  select(event_id) %>%
  unique() %>%
  mutate(group_name = "alcohol_drug")

# maternal MH
maternal_MH = non_journey %>%
  filter(role %in% c('mother', 'father'),
         stage_name == 'pre_post',
         time == 0,
         description == "program with maternal MH team") %>%
  select(event_id) %>%
  unique() %>%
  mutate(group_name = "maternal_MH")

#### qualification groups ----
# certificate qualificiation
certificate_qualificiation = non_journey %>%
  filter(role %in% c('mother', 'father'),
         stage_name == 'pre_post',
         time == -100,
         description == "qual level awarded") %>%
  group_by(event_id) %>%
  summarise(value = max(value)) %>%
  filter(value %in% c(1,2,3,4)) %>%
  select(event_id) %>%
  unique() %>%
  mutate(group_name = "certificate_qualificiation")

# graduate qualificiation
graduate_qualificiation = non_journey %>%
  filter(role %in% c('mother', 'father'),
         stage_name == 'pre_post',
         time == -100,
         description == "qual level awarded") %>%
  group_by(event_id) %>%
  summarise(value = max(value)) %>%
  filter(value %in% c(5,6,7)) %>%
  select(event_id) %>%
  unique() %>%
  mutate(group_name = "graduate_qualificiation")

# postgrad qualificiation
postgrad_qualificiation = non_journey %>%
  filter(role %in% c('mother', 'father'),
         stage_name == 'pre_post',
         time == -100,
         description == "qual level awarded") %>%
  group_by(event_id) %>%
  summarise(value = max(value)) %>%
  filter(value %in% c(8,9,10)) %>%
  select(event_id) %>%
  unique() %>%
  mutate(group_name = "postgrad_qualificiation")

# no qualificiation
qualification = non_journey %>%
  filter(role %in% c('mother', 'father'),
         stage_name == 'pre_post',
         time == -100,
         description == "qual level awarded",
         value != 0) %>%
  select(event_id) %>%
  unique()

no_qualificiation = non_journey %>%
  select(event_id) %>%
  unique() %>%
  anti_join(qualification, by ='event_id') %>%
  mutate(group_name = "no_qualificiation")

#### B4SC groups ----
# B4SC any declined
b4sc_declined = non_journey %>%
  filter(role == 'baby',
         stage_name == 'pre_post',
         time == 100,
         description %in% c("behavior_p declined",
                            "behavior_q declined",
                            "development declined")) %>%
  select(event_id) %>%
  unique() %>%
  mutate(group_name = "b4sc_any_declined")

# B4SC any declined
b4sc_declined_harsh = non_journey %>%
  filter(role == 'baby',
         stage_name == 'pre_post',
         time == 100,
         description %in% c("behavior_p declined",
                            "development declined")) %>%
  select(event_id) %>%
  unique() %>%
  mutate(group_name = "b4sc_declined_harsh")

# B4SC any need
b4sc_need = non_journey %>%
  filter(role == 'baby',
         stage_name == 'pre_post',
         time == 100,
         description %in% c("behavior_p need",
                            "behavior_q need",
                            "development need")) %>%
  select(event_id) %>%
  unique() %>%
  mutate(group_name = "b4sc_any_need")

# B4SC all pass
b4sc_pass = non_journey %>%
  filter(role == 'baby',
         stage_name == 'pre_post',
         time == 100,
         description %in% c("behavior_p pass",
                            "behavior_q pass",
                            "development pass")) %>%
  group_by(event_id) %>%
  summarise(num = n()) %>%
  filter(num == 3) %>%
  select(event_id) %>%
  mutate(group_name = "b4sc_all_pass")

#### maternity groups ----
# low birth weight
low_birth_weight = non_journey %>%
  filter(role == 'baby',
         stage_name == 'journey',
         time == 0,
         description == "BIRTH WEIGHT",
         value <= 2000) %>%
  select(event_id) %>%
  unique() %>%
  mutate(group_name = "low_birth_weight")

# maternal tobacco concern
maternal_tobacoo_concern = non_journey %>%
  filter(role == 'mother',
         stage_name == 'journey',
         time == 0,
         description == "maternity tobacco concern",
         value >= 2) %>%
  select(event_id) %>%
  unique() %>%
  mutate(group_name = "maternal_tobacoo_concern")

# hard birth (concerns at birth)
hard_birth = non_journey %>%
  filter(role == 'mother',
         stage_name == 'journey',
         time == 0,
         description == "number of concerns at birth",
         value >= 3) %>%
  select(event_id) %>%
  unique() %>%
  mutate(group_name = "hard_birth")

# hard pregnancy (concerns during pregnancy)
hard_pregnancy = non_journey %>%
  filter(role == 'mother',
         stage_name == 'journey',
         time == 0,
         description == "number of concerns during pregnancy",
         value >= 2) %>%
  select(event_id) %>%
  unique() %>%
  mutate(group_name = "hard_pregnancy")

# first pregnancy
first_pregnancies = non_journey %>%
  filter(role == 'mother',
         stage_name == 'journey',
         time == 0,
         description == 'previous pregnancies',
         value == 1) %>%
  select(event_id) %>%
  unique() %>%
  mutate(group_name = "first_pregnancy")

# ease of completing pregnancy
prev_complete_preg = non_journey %>%
  filter(role == 'mother',
         stage_name == 'journey',
         time == 0,
         description == "previous completed pregnancies")

prev_preg = non_journey %>%
  filter(role == 'mother',
         stage_name == 'journey',
         time == 0,
         description == "previous pregnancies")

hard_to_term = prev_complete_preg %>%
  inner_join(prev_preg, by = c("snz_uid", "event_id"), suffix = c("_complete","")) %>%
  mutate(difference = value - value_complete) %>%
  filter(5 <= difference, difference <= 12) %>%
  select(event_id) %>%
  unique() %>%
  mutate(group_name = "hard_to_carry_pregnancy_to_term")

# young mother
teen_mother = non_journey %>%
  filter(role == 'mother',
         stage_name == 'journey',
         time == 0,
         description == "Mothers age at birth",
         value <= 19) %>%
  select(event_id) %>%
  unique() %>%
  mutate(group_name = "teen_mother")

# older mother
older_mother = non_journey %>%
  filter(role == 'mother',
         stage_name == 'journey',
         time == 0,
         description == "Mothers age at birth",
         value >= 40) %>%
  select(event_id) %>%
  unique() %>%
  mutate(group_name = "older_mother")

#### local board groups ----
# local board
local_board = non_journey %>%
  filter(source == 'local board') %>%
  select(event_id, group_name = description) %>%
  unique()

# whole area
all_events = non_journey %>%
    select(event_id) %>%
    unique() %>%
    mutate(group_name = GATHERED_DATA_TABLE)

## consolodate groups ----

if(!SINGLE_LARGE_AREA_MODE)
  # gather all constructed group
  all_groups = rbind(data.table(event_clusters),
                     data.table(alcohol_drug),
                     data.table(b4sc_declined),
                     data.table(b4sc_declined_harsh),
                     data.table(b4sc_need),
                     data.table(b4sc_pass),
                     data.table(certificate_qualificiation),
                     data.table(chronic_condition),
                     data.table(ethnic_asian),
                     data.table(ethnic_european),
                     data.table(ethnic_maori),
                     data.table(ethnic_other),
                     data.table(ethnic_pacific),
                     data.table(first_pregnancies),
                     data.table(graduate_qualificiation),
                     data.table(hard_birth),
                     data.table(hard_pregnancy),
                     data.table(hard_to_term),
                     data.table(low_birth_weight),
                     data.table(maternal_MH),
                     data.table(maternal_tobacoo_concern),
                     data.table(new_migrants),
                     data.table(no_qualificiation),
                     data.table(older_mother),
                     data.table(postgrad_qualificiation),
                     data.table(prev_sentence),
                     data.table(teen_mother),
                     data.table(local_board),
                     data.table(all_events),
                     use.names = TRUE)

# remove unneeded & large datasets
# Commented for Testing - Uncommment after test execution - ACHOK001
# if(! DEVELOPMENT_MODE)
#   rm("alcohol_drug", "b4sc_declined", "b4sc_need", "b4sc_pass", "b4sc_declined_harsh",
#      "certificate_qualificiation", "chronic_condition",
#      "ethnic_asian", "ethnic_european", "ethnic_maori", "ethnic_other",
#      "ethnic_pacific", "first_pregnancies", "graduate_qualificiation", "hard_birth", "hard_pregnancy",
#      "hard_to_term", "low_birth_weight", "maternal_MH", "maternal_tobacoo_concern", "new_migrants", 
#      "no_qualificiation", "older_mother", "postgrad_qualificiation", "prev_sentence", "teen_mother",
#      "local_board")

# discard groupsif only wanting a singlelarge area
if(SINGLE_LARGE_AREA_MODE)
  all_groups = all_events

## summary of non-journey ----

run_time_inform_user("output non-journey results")

# totals
totals_results = non_journey %>%
  inner_join(all_groups, by = "event_id") %>%
  group_by(group_name, role, stage_name, time_unit, time, source, description) %>%
  summarise(num_events = n_distinct(event_id),
            num_people = n_distinct(snz_uid),
            total_value = sum(as.numeric(value)))
   
# histogram
histogram_results = non_journey %>%
  inner_join(all_groups, by = "event_id") %>%
  filter(description %in% c("ED visit", "exposed to family violence", "Mothers age at birth",
                            "non-enrolled PHO contact", "number of concerns at birth",
                            "number of concerns during pregnancy", "previous completed pregnancies",
                            "previous pregnancies", "BIRTH WEIGHT")) %>%
  group_by(group_name, role, stage_name, time_unit, time, source, description, value) %>%
  summarise(num_events = n_distinct(event_id),
            num_people = n_distinct(snz_uid),
            num_w_value = n())

# write output
write.csv(totals_results, file = "totals_results.csv", row.names = FALSE)
write.csv(histogram_results, file = "histogram_results.csv", row.names = FALSE)

## summary of journey ----
# Integrating Athira's work

run_time_inform_user("output jounrey results")

# get list of unique groups
group_size = all_groups %>%
  group_by(group_name) %>%
  summarise(num = n())
group_list = group_size[,1]

output_representative_timelines = data.frame(stringsAsFactors = FALSE)

# iterate through each group
for(jj in 1:nrow(group_size)){
  # inform user
  run_time_inform_user(sprintf("-- group: %d", jj))
  # extract group
  this_group = all_groups %>%
    filter(group_name == group_size$group_name[jj]) %>%
    inner_join(journey_prepared, by = "event_id", suffix = c("_g",""))
  
  # list of journeys
  unique_journeys = this_group %>%
    select(group_name, role, source, description) %>%
    unique()
  
  # for each unique journey
  for(ii in 1:nrow(unique_journeys)){
    # select records to make representative
    this_pivot_journey = this_group %>%
      filter(group_name == unique_journeys$group_name[ii],
             role == unique_journeys$role[ii],
             source == unique_journeys$source[ii],
             description == unique_journeys$description[ii]) %>%
      # select(time, value) %>%
      mutate(value = pmin(value, 1)) %>%
      spread(time, value, fill = 0)
    
    # just columns of journey
    this_pivot_journey = this_pivot_journey %>%
      select(TIMELINE_COLUMNS[TIMELINE_COLUMNS %in% colnames(this_pivot_journey)]) %>%
      as.data.frame()
    
    # ensure all required columns are present
    missing_cols = setdiff(TIMELINE_COLUMNS, names(this_pivot_journey))
    this_pivot_journey[missing_cols] = 0
    this_pivot_journey = this_pivot_journey[TIMELINE_COLUMNS]
    
    # number of timeline events in representative timeline
    num_representative_events = round(sum(this_pivot_journey) / nrow(this_pivot_journey))
    
    if(num_representative_events >= 1){
      # make representative timeline
      representative_timeline = make_representative_timeline(this_pivot_journey,
                                                             num_representative_events,
                                                             TIMELINE_COLUMNS)
      
      # add key details
      representative_timeline = representative_timeline %>%
        mutate(group_name = unique_journeys$group_name[ii],
               role = unique_journeys$role[ii],
               source = unique_journeys$source[ii],
               description = unique_journeys$description[ii],
               num_contributing_indiv = nrow(this_pivot_journey),
               group_size = group_size$num[jj])
      
      # append to dataset
      output_representative_timelines = rbind(output_representative_timelines, 
                                               representative_timeline)
    }
  }
}

# write output
write.csv(output_representative_timelines, file = "representative_timelines.csv", row.names = FALSE)

## conclude ----


run_time_inform_user("---- GRAND END ----")
