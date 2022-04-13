#' Enveomics: Data Frame to Dist
#' 
#' Transform a dataframe (or coercible object, like a table) into a
#' \strong{dist} object.
#' 
#' @param x A dataframe (or coercible object) with at least three columns:
#' \enumerate{
#'    \item ID of the object 1, 
#'    \item ID of the object 2, and 
#'    \item distance between the two objects.}
#' @param obj1.index Index of the column containing the ID of the object 1.
#' @param obj2.index Index of the column containing the ID of the object 2.
#' @param dist.index Index of the column containing the distance.
#' @param default.d Default value (for missing values).
#' @param max.sim If not zero, assumes that the values are similarity
#' (not distance) and this is the maximum similarity (corresponding to 
#' distance 0). Applies transformation: 
#' \eqn{distance = (max.sim - values)/max.sim.}
#' 
#' @return Returns a \strong{dist} object.
#' 
#' @author Luis M. Rodriguez-R [aut, cre]
#'
#' @examples
#' # A sparse matrix representation of similarities as data frame.
#' # The column "extra_data" is meaningless, only included to illustrate
#' # the use of the obj*.index parameters
#' sim <- data.frame(
#'   extra_data = c(0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.5),
#'   query      = c("A", "A", "A", "B", "C", "C", "D"),
#'   subject    = c("A", "B", "C", "B", "C", "B", "A"),
#'   similarity = c(100,  90,  60, 100, 100,  70,  10)
#' )
#' dist <- enve.df2dist(sim, "query", "subject", "similarity", max.sim = 100)
#' print(dist)
#' 
#' @export
enve.df2dist <- function(
  x,
  obj1.index = 1,
  obj2.index = 2,
  dist.index = 3,
  default.d  = NA,
  max.sim    = 0
) {
  x <- as.data.frame(x)
  a <- as.character(x[, obj1.index])
  b <- as.character(x[, obj2.index])
  d <- as.double(x[, dist.index])
  if (max.sim != 0) d <- (max.sim - d) / max.sim
  ids <- unique(c(a, b))
  m <- matrix(
    default.d, nrow = length(ids), ncol = length(ids), dimnames = list(ids, ids)
  )
  diag(m) <- 0.0
  m[cbind(a, b)] <- d
  m <- pmin(m, t(m), na.rm = TRUE)
  return(as.dist(m))
}

#' Enveomics: Data Frame to Dist (Group)
#' 
#' Transform a dataframe (or coercible object, like a table) into a 
#' \strong{dist} object, where there are 1 or more distances between each pair 
#' of objects.
#' 
#' @param x A dataframe (or coercible object) with at least three columns:
#' \enumerate{
#'    \item ID of the object 1, 
#'    \item ID of the object 2, and 
#'    \item distance between the two objects.
#' }
#' @param obj1.index Index of the column containing the ID of the object 1.
#' @param obj2.index Index of the column containing the ID of the object 2.
#' @param dist.index Index of the column containing the distance.
#' @param summary Function summarizing the different distances between the 
#' two objects.
#' @param empty.rm Remove rows with empty or \code{NA} groups.
#' 
#' @return Returns a \strong{dist} object.
#'
#' @author Luis M. Rodriguez-R [aut, cre]
#' 
#' @examples
#' # A sparse matrix representation of distances as data frame.
#' # Note that some pairs are repeated.
#' dist.df <- data.frame(
#'   query    = c("A", "A", "A", "B", "C", "C", "B", "B", "B"),
#'   subject  = c("A", "B", "C", "B", "C", "B", "A", "C", "C"),
#'   distance = c(  0, 0.1, 0.4,   0,   0, 0.4, 0.2, 0.2, 0.1)
#' )
#' dist <- enve.df2dist.group(dist.df)
#' print(dist)
#' 
#' # Use the mean of all repeated occurrences instead of the median.
#' dist <- enve.df2dist.group(dist.df, summary = mean)
#' 
#' # Simply use the first occurrence for any given pair.
#' dist <- enve.df2dist.group(dist.df, summary = function(x) head(x, n = 1))
#' 
#' @export
enve.df2dist.group <- function(
  x,
  obj1.index = 1,
  obj2.index = 2,
  dist.index = 3,
  summary    = median,
  empty.rm   = TRUE
) {
  x <- as.data.frame(x)
  if(empty.rm)
    x <- x[
      !(is.na(x[, obj1.index]) |
      is.na(x[, obj2.index]) |
      x[, obj1.index] == "" |
      x[, obj2.index] == ""),
    ]
  a <- as.character(x[, obj1.index])
  b <- as.character(x[, obj2.index])
  d <- as.double(x[, dist.index])
  ids <- unique(c(a, b))
  if (length(ids) < 2) return(NA)
  m <- matrix(
    NA, nrow = length(ids), ncol = length(ids), dimnames = list(ids, ids)
  )
  diag(m) <- 0
  for (i in 2:length(ids)) {
    id.i <- ids[i]
    for (j in 1:(i - 1)) {
      id.j <- ids[j]
      d.ij <- summary(c(d[a == id.i & b == id.j], d[b == id.i & a == id.j]))
      m[id.i, id.j] <- d.ij
      m[id.j, id.i] <- d.ij
    }
  }
  return(as.dist(m))
}

#' Enveomics: Data Frame to Dist (List)
#' 
#' Transform a dataframe (or coercible object, like a table)
#' into a \strong{list} of \strong{dist} objects, one per group.
#' 
#' @param x A dataframe (or coercible object) with at least three columns:
#' \enumerate{
#'    \item ID of the object 1, 
#'    \item ID of the object 2, and 
#'    \item distance between the two objects.}
#' @param groups Named array where the IDs correspond to the object IDs,
#' and the values correspond to the group.
#' @param obj1.index Index of the column containing the ID of the object 1.
#' @param obj2.index Index of the column containing the ID of the object 2.
#' @param dist.index Index of the column containing the distance.
#' @param empty.rm Remove incomplete matrices.
#' @param ... Any other parameters supported by \code{\link{enve.df2dist}}.
#' 
#' @return Returns a \strong{list} of \strong{dist} objects.
#'
#' @author Luis M. Rodriguez-R [aut, cre]
#'
#' @export

enve.df2dist.list <- function(
  x,
  groups,
  obj1.index = 1,
  obj2.index = 2,
  dist.index = 3,
  empty.rm   = TRUE,
  ...
) {
  x <- as.data.frame(x)
  a <- as.character(x[, obj1.index])
  b <- as.character(x[, obj2.index])
  d <- as.numeric(x[, dist.index])
  ids.all <- unique(c(a, b))
  l <- list()
  same_group <- groups[a] == groups[b]
  same_group <- ifelse(is.na(same_group), FALSE, TRUE)
  for (group in unique(groups)) {
    ids <- ids.all[groups[ids.all] == group]
    if (length(ids) > 1 & group != "") {
      x.sub <- x[same_group & (groups[a] == group) & (groups[b] == group), ]
      if (nrow(x.sub) > 0) {
        d.g <- enve.df2dist(x.sub, obj1.index, obj2.index, dist.index, ...)
        if(!empty.rm | !any(is.na(d.g))) l[[group]] <- d.g
      }
    }
  }
  return(l)
}

