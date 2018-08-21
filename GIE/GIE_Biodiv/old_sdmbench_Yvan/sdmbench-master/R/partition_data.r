#' Partition spatial data
#'
#' A function that partitions spatial data in order to avoid spatial autocorrelation.
#' @param dataset_raster A raster dataset.
#' @param dataset A dataframe containing species occurences.
#' @param env A raster dataset containing the Bioclim variables.
#' @param method A character string representing the desired spatial partitioning method.
#'
#' @return A dataframe partitionined using the selected method.
#' @examples
#' benchmarking_data <- get_benchmarking_data("Lynx lynx", limit = 1500, climate_resolution = 10)
#' benchmarking_data$df_data <- partition_data(dataset_raster = benchmarking_data$raster_data, dataset = benchmarking_data$df_data, env = benchmarking_data$raster_data$climate_variables, method = "block")
partition_data <- function(dataset_raster, dataset, env, method) {
    if (method == "default") {
        result_dataset <- dataset
        return(result_dataset)
    }
    if (method == "block") {
        blocks <- ENMeval::get.block(occ = dataset_raster$coords_presence,
                                     bg.coords = dataset_raster$background)
        # the blocks_vector is used for partitioning during benchmarking
        blocks_vector <- c(blocks$occ.grp, blocks$bg.grp)
        result_dataset <- dataset
        result_dataset$grp <- blocks_vector
        return(result_dataset)

    } else if (method == "checkerboard1") {
        check1 <- ENMeval::get.checkerboard1(occ = dataset_raster$coords_presence,
                                             env = env,
                                             bg.coords = dataset_raster$background,
                                             aggregation.factor = 5)
        nk <- length(unique(check1$occ.grp))
        pres <- as.data.frame(raster::extract(dataset_raster$climate_variables, dataset_raster$coords_presence))
        bg <- as.data.frame(raster::extract(dataset_raster$climate_variables, dataset_raster$background))


        for (k in 1:nk) {
            train_val <- pres[check1$occ.grp != k, , drop = FALSE]
            test_val <- pres[check1$occ.grp == k, , drop = FALSE]
            bg_val <- bg[check1$bg.grp != k, , drop = FALSE]
        }

        train_val$grp <- "train"
        test_val$grp <- "test"
        bg_val$grp <- "bg"

        result_dataset <- rbind(train_val, test_val, bg_val)

        # sample from background points
        bg_rows <- as.integer(row.names(result_dataset)[result_dataset$grp == "bg"])
        bg_rows_idx <- sample.int(length(bg_rows), size = 1/2 * length(bg_rows))

        bg_rows_train <- bg_rows[bg_rows_idx]
        bg_rows_test <- bg_rows[-bg_rows_idx]

        grp1_indeces <- as.integer(row.names(result_dataset)[result_dataset$grp == "train"])
        grp1_indeces <- c(grp1_indeces, bg_rows_train)
        grp2_indeces <- as.integer(row.names(result_dataset)[result_dataset$grp == "test"])
        grp2_indeces <- c(grp2_indeces, bg_rows_test)

        # use custom splitting
        where <- match(row.names(result_dataset), grp1_indeces)
        where <- ifelse(is.na(where), 1, 0)
        result_dataset$grp_checkerboard <- where

        # construct label
        result_dataset$grp_checkerboard <- as.factor(result_dataset$grp_checkerboard)
        result_dataset$label <- ifelse(result_dataset$grp != "bg", 1, 0)
        result_dataset$label <- as.factor(result_dataset$label)

        result_dataset$grp <- NULL

        return(result_dataset)

    } else if (method == "checkerboard2") {
        check2 <- ENMeval::get.checkerboard2(occ = dataset_raster$coords_presence,
                                             env = env,
                                             bg.coords = dataset_raster$background,
                                             aggregation.factor = c(5, 5))

        nk <- length(unique(check2$occ.grp))
        pres <- as.data.frame(raster::extract(dataset_raster$climate_variables, dataset_raster$coords_presence))
        bg <- as.data.frame(raster::extract(dataset_raster$climate_variables, dataset_raster$background))

        for (k in 1:nk) {
            train_val <- pres[check2$occ.grp != k, , drop = FALSE]
            test_val <- pres[check2$occ.grp == k, , drop = FALSE]
            bg_val <- bg[check2$bg.grp != k, , drop = FALSE]
        }

        train_val$grp <- "train"
        test_val$grp <- "test"
        bg_val$grp <- "bg"

        result_dataset <- rbind(train_val, test_val, bg_val)

        bg_rows <- as.integer(row.names(result_dataset)[result_dataset$grp == "bg"])
        bg_rows_idx <- sample.int(length(bg_rows), size = 1/2 * length(bg_rows))

        bg_rows_train <- bg_rows[bg_rows_idx]
        bg_rows_test <- bg_rows[-bg_rows_idx]

        grp1_indeces <- as.integer(row.names(result_dataset)[result_dataset$grp == "train"])
        grp1_indeces <- c(grp1_indeces, bg_rows_train)
        grp2_indeces <- as.integer(row.names(result_dataset)[result_dataset$grp == "test"])
        grp2_indeces <- c(grp2_indeces, bg_rows_test)

        where <- match(row.names(result_dataset), grp1_indeces)
        where <- ifelse(is.na(where), 1, 0)
        result_dataset$grp_checkerboard <- where

        result_dataset$grp_checkerboard <- as.factor(result_dataset$grp_checkerboard)
        result_dataset$label <- ifelse(result_dataset$grp != "bg", 1, 0)
        result_dataset$label <- as.factor(result_dataset$label)

        result_dataset$grp <- NULL

        return(result_dataset)
    }
}
