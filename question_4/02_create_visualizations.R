library(ggplot2)
library(pharmaverseadam)
library(dplyr)
library(forcats)
library(scales)

# PLOT 1
# AE severity distribution by treatment (bar chart or heatmap). AE Severity is captured in the AESEV variable in pharmaverseadam::adae dataset.

adae <- pharmaverseadam::adae |> 
  # keep treatment emergent AEs and safety population
  filter(TRTEMFL == "Y",
        SAFFL == "Y")

# create plot
plot_1 <- ggplot(adae, aes(x = TRT01A, fill = AESEV)) +
  geom_bar() +
  labs(title = "AE Severity distribution by treatment, Safety Population",
       y = "Count of AEs",
       x = "Treatment Arm",
       caption = "Only treatment emergent adverse events are considered.") +
  theme(plot.caption = element_text(hjust = 0))

# save plot
ggsave("./question_4/plot_1.png",plot_1)

# PLOT 2
# Top 10 most frequent AEs (with 95% CI for incidence rates). AEs are captured in the AETERM variable in pharmaverseadam::adae dataset.

unique_patients <- length(unique(adae$USUBJID))

top10_ae <- adae |> 
            # keep only one record per patient, per AETERM |> 
            distinct(USUBJID, AETERM) |> 
            group_by(AETERM) |>
            # count unique patients
            summarize(total_events = n(),
                      perc_events = 100*total_events/unique_patients) |>
            # compute Clopper-Pearson CIs
            rowwise() |> 
            mutate(ci_low = binom.test(total_events, unique_patients)$conf.int[1] * 100,
                   ci_hi  = binom.test(total_events, unique_patients)$conf.int[2] * 100) |> 
            ungroup() |> 
            # sort in descending order
            arrange(-total_events) |> 
            # select top 10 events
            slice_head(n = 10) 

plot_2 <- ggplot(top10_ae, aes(x = fct_reorder(AETERM, perc_events), y = perc_events, ymin = ci_low, ymax = ci_hi)) +
  geom_point(size = 2) +
  geom_errorbar(height = 0.3)+
  coord_flip() +
  labs(y = "Percentage of Patients (%)",
       x = NULL,
       title = "Top 10 Most Frequent Adverse Events, Safety Population",
       subtitle = paste0("n = ", unique_patients, "; 95% Clopper-Pearson CIs"),
       caption = "Only treatment emergent adverse events are considered.") +
  scale_y_continuous(labels = label_percent(scale = 1))
  
ggsave("./question_4/plot_2.png", plot_2, width = 7.5)