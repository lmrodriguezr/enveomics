
enve.prune.dist <- function
### Automatically prunes a tree, to keep representatives of each clade.
   (t,
### A `phylo` object
   dist.quantile=0.25,
### The quantile of pairwise distances.
   min_dist,
### The minimum distance to allow between two tips. If not set, dist.quantile is
### used instead to calculate it.
   quiet=FALSE,
### Boolean indicating if the function must run without output.
   max_iters=100){
   if(!require(picante, quietly=TRUE)) stop('Unavailable picante library.');
   if(missing(min_dist)){
      if(dist.quantile>0){
	 min_dist <- as.numeric(quantile(t$edge.length, dist.quantile));
      }else{
         min_dist <- as.numeric(min(t$edge.length[t$edge.length>0]));
      }
   }
   if(!quiet) cat('\nObjective minimum distance:',min_dist,'\n');
   round=1;
   while(round <= max_iters){
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
	 round <- round + 1;
      }else{
	 break;
      }
   }
   return(t);
### Returns a pruned phylo object.
}

enve.__prune.iter <- function
### Internal function for enve.prune.dist
   (t,
   dist,
   min_dist,
   quiet){
   if(!require(picante, quietly=TRUE)) stop('Unavailable picante library.');
   ori_len <- length(t$tip.label);
   # Prune
   if(!quiet) pb <- txtProgressBar(1, ncol(dist)-1, style=3);
   ignore <- c();
   for(i in 1:(ncol(dist)-1)){
      if(i %in% ignore) next;
      for(j in (i+1):nrow(dist)){
	 if(dist[j, i]<min_dist){
	    t <- drop.tip(t, rownames(dist)[j]);
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

