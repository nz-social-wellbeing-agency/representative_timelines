#####################################################################################################
#' Description: Command script for producing Journey Timelines
#'
#' Input: 
#'
#' Output: 
#' 
#' Author: Simon Anastasiadis
#' 
#' Dependencies:
#' - utility_functions.R
#' - journey_timelines_functions.R
#' 
#' Notes: Last runtime: 20 min in development mode, 5.5hrs in full mode
#' (increases to 2.5 hours in development mode if lack of hard drive space prevents easy sort)
#' 
#' Issues:
#' 
#' History (reverse order):
#' 2018-12-10 SA v0
#' 2018-12-20 SA v1
#####################################################################################################

## source ----
setwd(paste0("~/Network-Shares/DataLabNas/MAA/MAA2016-15 Supporting the Social Investment Unit/",
             "Journey timelines - HaBiSA/rprogs"))
source('utility_functions.R')
source('journey_timelines_functions.R')

## parameters ----

# user controls
DEVELOPMENT_MODE = TRUE                       
CAUTIOUS_MODE = TRUE
SINGLE_LARGE_AREA_MODE = FALSE
OUTPUT_TABLE = "jt_intersect_union"
# input tables
STAGE_DEFINITION_CSV_FILE = "stage_details.csv"
MEASURE_PROCESS_CSV_FILE = "measures_process.csv"
DESCRIPTION_RENAMES_CSV_FILE = "description_rename.csv"
EVENT_TABLE = "jt_event_locations"
# EVENT_TABLE = "jt_event_locations_AKL"
# EVENT_TABLE = "jt_event_locations_NZ"
ROLE_TABLE = "jt_event_roles"
# other
REQUIRED_MEASURE_COLUMNS = c("snz_uid", "start_date", "end_date", "description", "value", "source")
REQUIRED_OUTPUT_COLUMNS = c("snz_uid", "role", "event_id", 
                            "stage_name", "time_unit", "time", "description", "source", "value")

## setup ----

run_time_inform_user("---- GRAND START ----")
db_con_IDI_sandpit = create_database_connection(database = "IDI_Sandpit")
our_schema = "[IDI_Sandpit].[DL-MAA2016-15]"
our_view = "[IDI_UserCode].[DL-MAA2016-15]"
purge_tables_by_prefix(db_con_IDI_sandpit, our_schema, "jt_tmp_")

## load control files ----

run_time_inform_user("loading control files")

stage_definitions = read.csv2(file = STAGE_DEFINITION_CSV_FILE, header = TRUE, sep = ",",
                              stringsAsFactors = FALSE)
required_columns = c("subset", "stage_name_label", "time_unit_label", "time_label",
                     "datediff_unit", "datediff_to_start", "datediff_to_end")
assert(table_contains_required_columns(stage_definitions, required_columns),
       "stage definition lacks required column")


measure_processes = read.csv2(file = MEASURE_PROCESS_CSV_FILE, header = TRUE, sep = ",",
                              stringsAsFactors = FALSE)
required_columns = c("table_name", "role_baby", "role_mother", "role_father", "role_sibling", 
                     "merge_compact", "intersection_combine", "timeline_event", "recent_pre_post",
                     "past", "future", "ever", "timeline_path")
assert(table_contains_required_columns(measure_processes, required_columns),
       "measure process lacks required column")


description_renames = read.csv2(file = DESCRIPTION_RENAMES_CSV_FILE, header = TRUE, sep = ",",
                                stringsAsFactors = FALSE)
required_columns = c("source", "description", "rename_to")
assert(table_contains_required_columns(description_renames, required_columns),
       "descrip rename lacks required column")

# write to SQL
description_columns = list(source = "[varchar](25) NOT NULL",
                           description = "[varchar](80) NOT NULL",
                           rename_to = "[varchar](80) NOT NULL")
description_renames = copy_r_to_sql(db_con_IDI_sandpit, our_schema, "jt_tmp_description_renames",
                                    description_renames, description_columns, OVERWRITE = TRUE)

## load event tables ----

run_time_inform_user("creating access points")

events = create_access_point(db_connection =  db_con_IDI_sandpit,
                             schema =  our_view,
                             tbl_name = EVENT_TABLE,
                             db_hack = TRUE)

required_columns = c("event_id", "event_date")
assert(table_contains_required_columns(events, required_columns, only = FALSE),
       msg = "event table does not contain all required columns")

roles = create_access_point(db_connection =  db_con_IDI_sandpit,
                             schema =  our_view,
                             tbl_name = ROLE_TABLE,
                            db_hack = TRUE)

required_columns = c("snz_uid", "role", "event_id")
assert(table_contains_required_columns(roles, required_columns, only = FALSE),
       msg = "roles table does not contain all required columns")

if(DEVELOPMENT_MODE){
  run_time_inform_user("Imposing DEVELOPMENT MODE")
  events = events %>% filter(event_id %% 1000 == 0)
  roles = roles %>% filter(role == "mother")
}

if(!DEVELOPMENT_MODE & SINGLE_LARGE_AREA_MODE){
  run_time_inform_user("        Imposing SINGLE LARGE AREA MODE")
  # filter to 10,000 random events
  num_events = events %>% summarise(n_distinct(event_id)) %>% collect() %>% unlist(use.names = FALSE)
  scaling_factor = floor(num_events / 10000)
  events = events %>% filter(event_id %% scaling_factor == 0)
}

## create output table ----

intersect_union_table_columns = list(snz_uid = "[int] NOT NULL",
                                     role = "[varchar](20) NOT NULL",
                                     event_id = "[int] NOT NULL",
                                     stage_name = "[varchar](25) NOT NULL",
                                     time_unit = "[varchar](25) NOT NULL",
                                     time = "[int] NOT NULL",
                                     description = "[varchar](80) NOT NULL",
                                     source = "[varchar](25) NOT NULL",
                                     value = "[int] NOT NULL")

intersect_union = create_table(db_con_IDI_sandpit, schema = our_schema, tbl_name = "jt_intersect_union",
                               named_list_of_columns = intersect_union_table_columns, OVERWRITE = TRUE)

## list identities for analysis ----

# all snz_uid required for this analysis (used to focus measure analysis)
all_needed_snz_uid = events %>%
  inner_join(roles, by = "event_id") %>%
  select(snz_uid)


all_needed_snz_uid = write_for_reuse(db_con_IDI_sandpit, our_schema, "jt_tmp_all_snz_uid",
                                     all_needed_snz_uid, index_columns = "snz_uid")

## create event stages ----

run_time_inform_user("making event stages")

event_stages = produce_event_stages(db_con_IDI_sandpit, our_schema, "jt_tmp_stage_events",
                                    roles, events, stage_definitions)

#### for each measure ----

for(ii in 1:nrow(measure_processes)){
  
  tbl_name = measure_processes$table_name[ii] %>% trimws(which = "both")
  # inform user
  run_time_inform_user(paste0("-- beginning with table: ",tbl_name))
  
  #### required stage types ----
  # out of: c("timeline_event", "recent_pre_post", "past", "future", "ever", "timeline_path")
  
  stage_types = c(
    if_else(measure_processes$timeline_event[ii] != "", "timeline_event", NULL),
    if_else(measure_processes$recent_pre_post[ii] != "", "recent_pre_post", NULL),
    if_else(measure_processes$past[ii] != "", "past", NULL),
    if_else(measure_processes$future[ii] != "", "future", NULL),
    if_else(measure_processes$ever[ii] != "", "ever", NULL),
    if_else(measure_processes$timeline_path[ii] != "", "timeline_path", NULL)
  )
  stage_types = stage_types[!is.na(stage_types)]
  
  #### for each stage-type ----
  for(type in stage_types){
    #### cautious mode ----
    if(CAUTIOUS_MODE){
      # recreate connection and tables
      db_con_IDI_sandpit = create_database_connection(database = "IDI_Sandpit")
      all_needed_snz_uid = create_access_point(db_con_IDI_sandpit, our_schema, "jt_tmp_all_snz_uid")
      event_stages = create_access_point(db_con_IDI_sandpit, our_schema, "jt_tmp_stage_events")
      description_renames = create_access_point(db_con_IDI_sandpit, our_schema,
                                                "jt_tmp_description_renames")
    }
    
    #### focus on required stages & roles ----
    
    wanted_roles = c(
      if_else(measure_processes$role_baby[ii] != "", "baby", NULL),
      if_else(measure_processes$role_mother[ii] != "", "mother", NULL),
      if_else(measure_processes$role_father[ii] != "", "father", NULL),
      if_else(measure_processes$role_sibling[ii] != "", "full sibling", NULL),
      if_else(measure_processes$role_sibling[ii] != "", "half sibling", NULL)
    )
    wanted_roles = wanted_roles[!is.na(wanted_roles)]
    
    this_event_stage = event_stages %>%
      filter(subset == type,
             role %in% wanted_roles)

    #### set up measure ----
    
    # load and check table
    this_measure = create_access_point(db_con_IDI_sandpit, our_view, tbl_name, db_hack = TRUE)
    assert(table_contains_required_columns(this_measure, REQUIRED_MEASURE_COLUMNS),
           "measure table lacking required columns")
    # limit to relevant people
    this_measure = this_measure %>%
      filter(start_date <= end_date) %>%
      semi_join(all_needed_snz_uid, by = "snz_uid")
    # rename
    this_measure = this_measure %>%
      inner_join(description_renames, by = c("source", "description")) %>%
      mutate(description = rename_to)
    
    #### compact if required ----
    compact_days_overlap = measure_processes$merge_compact[ii]
    if(!is.na(compact_days_overlap) & is.numeric(compact_days_overlap) & compact_days_overlap >= 0){
      
      run_time_inform_user("compacting")
      
      this_measure = compact_spells(this_measure,
                                    within = c("snz_uid", "description", "source"),
                                    start_date_col = "start_date",
                                    end_date_col = "end_date",
                                    db_connection = db_con_IDI_sandpit,
                                    schema = our_schema,
                                    overlap_days = compact_days_overlap,
                                    cols_to_sum = "value")
      
      this_measure = write_for_reuse(db_con_IDI_sandpit, our_schema, "jt_tmp_compacted",
                                     this_measure, index_columns = "snz_uid")
      
    }
    
    #### combine stages and measure ----
    
    run_time_inform_user("combine stages and measure")
    
    cols_to_duplicate = c("role", "event_id", "stage_name", "time_unit", "time", "description", "source")
    if(measure_processes$intersection_combine[ii] == "proportion"){
      cols_to_proportion = "value"
    } else {
      cols_to_duplicate = c(cols_to_duplicate, "value")
      cols_to_proportion = c()
    }
    
    combined_spells = combine_spells(this_event_stage, this_measure, within = "snz_uid",
                                     start_date_col = "start_date", end_date_col = "end_date",
                                     db_con_IDI_sandpit, our_schema,
                                     cols_to_duplicate = cols_to_duplicate,
                                     cols_to_proportion = cols_to_proportion)
    
    combined_spells = combined_spells %>% filter(!is.na(description), !is.na(event_id))
    
    combined_spells = write_for_reuse(db_con_IDI_sandpit, our_schema, "jt_tmp_combined_spells",
                                      combined_spells)
    
    #### write/append results out ----
    
    group_by_list = c("snz_uid", "role", "event_id", "stage_name", "time_unit", "time",
                      "description", "source")
    summary_type = measure_processes[[type]][ii]
    
    if(summary_type == "COUNT")
      combined_spells = combined_spells %>% group_by(!!!syms(group_by_list)) %>%
      summarise(value = n())
    if(summary_type == "MAX")
      combined_spells = combined_spells %>% group_by(!!!syms(group_by_list)) %>%
      summarise(value = max(value, na.rm = TRUE))
    if(summary_type == "SUM")
      combined_spells = combined_spells %>% group_by(!!!syms(group_by_list)) %>%
      summarise(value = sum(value, na.rm = TRUE))
    if(summary_type == "DURATION")
      combined_spells = combined_spells %>% group_by(!!!syms(group_by_list)) %>%
      mutate(value = DATEDIFF(DAY, start_date, end_date)) %>%
      summarise(value = sum(value, na.rm = TRUE))
    if(summary_type == "DISTINCT")
      combined_spells = combined_spells %>% group_by(!!!syms(group_by_list)) %>%
      summarise(value = n_distinct(value))
    
    run_time_inform_user("appending measure to output")
    
    append_database_table(db_con_IDI_sandpit, our_schema, OUTPUT_TABLE,
                          REQUIRED_OUTPUT_COLUMNS, combined_spells)
    
  }
  run_time_inform_user(paste0("-- end with table: ",tbl_name))
}
## conclude ----

purge_tables_by_prefix(db_con_IDI_sandpit, our_schema, "jt_tmp_")

run_time_inform_user("---- GRAND END ----")
