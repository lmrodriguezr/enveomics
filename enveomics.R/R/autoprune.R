#' Enveomics: Prune Dist
#' 
#' Automatically prunes a tree, to keep representatives of each clade.
#'
#' @param t A \strong{phylo} object or a path to the Newick file.
#' @param dist.quantile The quantile of edge lengths.
#' @param min_dist The minimum distance to allow between two tips.
#' If not set, \code{dist.quantile} is used instead to calculate it.
#' @param quiet Boolean indicating if the function must run without output.
#' @param max_iters Maximum number of iterations.
#' @param min_nodes_random 
#' Minimum number of nodes to trigger \emph{tip-pairs} nodes sampling. 
#' This sampling is less reproducible and more computationally expensive,
#' but it's the only solution if the cophenetic matrix exceeds \code{2^31-1} 
#' entries; above that, it cannot be represented in R.
#' @param random_nodes_frx 
#' Fraction of the nodes to be sampled if more than \code{min_nodes_random}.
#'
#' @return Returns a pruned \strong{phylo} object.
#'
#' @author Luis M. Rodriguez-R [aut, cre]
#'
#' @export

enve.prune.dist <- function
(t,
 dist.quantile=0.25,
 min_dist,
 quiet=FALSE,
 max_iters=100,
 min_nodes_random=4e4,
 random_nodes_frx=1
){
  if(!requireNamespace("ape", quietly=TRUE))
    stop('Unavailable ape library.');
  if(is.character(t)) t <- ape::read.tree(t)
  if(missing(min_dist)){
    if(dist.quantile>0){
      min_dist <- as.numeric(quantile(t$edge.length, dist.quantile));
    }else{
      min_dist <- as.numeric(min(t$edge.length[t$edge.length>0]));
    }
  }
  if(!quiet) cat('\nObjective minimum distance: ',min_dist,', initial tips: ',length(t$tip.label),'\n', sep='');
  round=1;
  while(round <= max_iters){
    if(length(t$tip.label) > min_nodes_random){
      if(!quiet) cat('  | Iter: ',round-1,', Tips: ', length(t$tip.label),
                     ', reducing tip-pairs.\n', sep='');
      rnd.nodes <- sample(t$tip.label, length(t$tip.label)*random_nodes_frx);
      t <- enve.__prune.reduce(t, rnd.nodes, min_dist, quiet);
    }else{
      if(!quiet) cat(' Gathering distances...\r');
      d <- cophenetic(t);
      diag(d) <- NA;
      if(!quiet) cat('  | Iter: ',round-1,', Tips: ', length(t$tip.label),
                     ', Median distance: ', median(d, na.rm=TRUE),
                     ', Minimum distance: ', min(d, na.rm=TRUE),
                     '\n', sep='');
      # Run iteration
      if(min(d, na.rm=TRUE) < min_dist){
        t <- enve.__prune.iter(t, d, min_dist, quiet);
      }else{
        break;
      }
    }
    round <- round + 1;
  }
  return(t);
}

#' Enveomics: Prune Reduce (Internal Function)
#' 
#' Internal function for \code{\link{enve.prune.dist}}.
#'
#' @param t 
#' @param nodes 
#' @param min_dist 
#' @param quiet 
#' 
#' @author Luis M. Rodriguez-R [aut, cre]
#'
#' @export

enve.__prune.reduce <- function
(t, nodes, min_dist, quiet){
  if(!quiet) pb <- txtProgressBar(1, length(nodes), style=3);
  for(i in 1:length(nodes)){
    node.name <- nodes[i];
    if(!quiet) setTxtProgressBar(pb, i);
    # Get node ID
    node <- which(t$tip.label==node.name);
    if(length(node)==0) next;
    # Get parent and distance to parent
    parent.node <- t$edge[ t$edge[,2]==node, 1];
    # Get edges to parent
    parent.edges <- which(t$edge[,1]==parent.node);
    stopit <- FALSE;
    for(j in parent.edges){
      for(k in parent.edges){
        if(j != k & t$edge[j,2]<length(t$tip.label) & t$edge[k,2]<length(t$tip.label) & sum(t$edge.length[c(j,k)]) < min_dist){
          t <- ape::drop.tip(t, t$edge[k,2]);
          stopit <- TRUE;
          break;
        }
      }
      if(stopit) break;
    }
  }
  if(!quiet) cat('\n');
  return(t);
}

#' Enveomics: Prune Iter (Internal Function)
#' 
#' Internal function for \code{\link{enve.prune.dist}}.
#'
#' @param t 
#' @param dist 
#' @param min_dist 
#' @param quiet 
#' 
#' @author Luis M. Rodriguez-R [aut, cre]
#'
#' @export

enve.__prune.iter <- function
(t,
 dist,
 min_dist,
 quiet){
  ori_len <- length(t$tip.label);
  # Prune
  if(!quiet) pb <- txtProgressBar(1, ncol(dist)-1, style=3);
  ignore <- c();
  for(i in 1:(ncol(dist)-1)){
    if(i %in% ignore) next;
    for(j in (i+1):nrow(dist)){
      if(dist[j, i]<min_dist){
        t <- ape::drop.tip(t, rownames(dist)[j]);
        ignore <- c(ignore, j);
        break;
      }
    }
    if(!quiet) setTxtProgressBar(pb, i);
  }
  if(!quiet) cat('\n');
  # Check if it droped tips
  cur_len <- length(t$tip.label);
  if(cur_len == ori_len){
    stop("Internal error: small edge found in tree, with no equivalent in distance matrix.\n");
  }
  return(t);
}

