
# Use as:
# > # Estimate reference (null) model:
# > dist <- as.dist(read.table('Ecoli-ML-dmatrix.txt', sep='\t', h=T, row.names=1));
# > all.dist <- enve.gss(dist);
# > 
# > # Estimate subset (test) model:
# > lee <- read.table('LEE-strains.txt', as.is=T)$V1
# > lee.dist <- enve.gss(dist, lee, subsamples=seq(0,1,by=0.05), threads=12, verbosity=2, pre.gss=all.dist.merge);
# ...
# > 
# > # Plot reference and selection at different subsampling levels:
# > plot(all.dist, t='boxplot');
# > plot(lee, new=FALSE, col='darkred');
# ...
# > 
# > # Test significance of overclustering (or overdispersion):
# > hly.test <- enve.gss.test(dist, lee, pre.gss=all.dist.merge, verbosity=2, threads=12);
# > summary(hly.test);
# > plot(hly.test);
# ...


#==============> Define S4 classes
setClass("enve.GSS",
   ### Enve-omics representation of "Generic-Space subsampling". This object represents sets
   ### of distances between objects, sampled nearly-uniformly at random in "distance space".
   ### Subsampling without selection is trivial, since both the distances space and the selection
   ### occur in the same transformed space. However, it's useful to compare randomly subsampled
   ### sets against a selected set of objects. This is intended to identify overdispersion or
   ### overclustering (see `enve.GSStest`) of a subset against the entire collection of objects
   ### with minimum impact of sampling biases. This object can be produced by `enve.gss` and
   ### supports S4 methods `plot` and `summary`.
   representation(
   distance='numeric',
   ### Centrality measurement of the distances between the selected objects (without subsampling).
   points='matrix',
   ### Position of the different objects in distance space.
   distances='matrix',
   ### Subsampled distances, where the rows are replicates and the columns are subsampling levels.
   spaceSize='numeric',
   ### Number of objects.
   selSize='numeric',
   ### Number of selected objects.
   dimensions='numeric',
   ### Number of dimensions in the distance space.
   subsamples='numeric',
   ### Subsampling levels (as fractions, from 0 to 1).
   call='call')
   ### Call producing this object.
   ,package='enveomics.R'
   );
setClass("enve.GSStest",
   ### Test of significance of overclustering or overdispersion in a selected set of objects with
   ### respect to the entire set (see `enve.GSS`). This object can be produced by `enve.gss.test`
   ### and supports S4 methods `plot` and `summary`.
   representation(
   pval.gt='numeric',
   ### P-value for the overdispersion test.
   pval.lt='numeric',
   ### P-value for the overclustering test.
   all.dist='numeric',
   ### Empiric PDF of distances for the entire dataset (subsampled at selection size).
   sel.dist='numeric',
   ### Empiric PDF of distances for the selected objects (without subsampling).
   diff.dist='numeric',
   ### Empiric PDF of the difference between `all.dist` and `sel.dist`. The p-values are
   ### estimating by comparing areas in this PDF greater than and lesser than zero.
   dist.mids='numeric',
   ### Midpoints of the empiric PDFs of distances.
   diff.mids='numeric',
   ### Midpoints of the empiric PDF of difference of distances.
   call='call')
   ### Call producing this object.
   ,package='enveomics.R'
   );

#==============> Define S4 methods
summary.enve.GSS <- function
   ### Summary of an `enve.GSS` object.
   (object,
   ### `enve.GSS` object.
   ...
   ### No additional parameters are currently supported.
   ){
   cat('===[ enve.GSS ]---------------------------\n');
   cat('Selected',attr(object,'selSize'),'of',attr(object,'spaceSize'),'objects in',attr(object,'dimensions'),'dimensions.\n');
   cat('Collected',length(attr(object,'subsamples')),'subsamples with',nrow(attr(object,'distances')),'replicates each.\n');
   cat('------------------------------------------\n');
   cat('call:',as.character(attr(object,'call')),'\n');
   cat('------------------------------------------\n');
}

plot.enve.GSS <- function
   ### Plot an `enve.GSS` object.
   (x,
   ### `enve.GSS` object to plot.
   new=TRUE,
   ### Should a new canvas be drawn?
   type=c('boxplot', 'points'),
   ### Type of plot. The 'points' plot shows all the replicates, the 'boxplot' plot represents the values found by `boxplot.stats`
   ### as areas, and plots the outliers as points.
   col='#00000044',
   ### Color of the areas and/or the points.
   pt.cex=1/2,
   ### Size of the points.
   pt.pch=19,
   ### Points character.
   pt.col=col,
   ### Color of the points.
   ln.col=col,
   ### Color of the lines.
   ...
   ### Any additional parameters supported by `plot`.
   ){
   type <- match.arg(type);
   plot.opts <- list(xlim=range(attr(x,'subsamples'))*attr(x,'selSize'), ylim=range(attr(x,'distances')), ..., t='n', x=1);
   if(new) do.call(plot, plot.opts);
   abline(h=attr(x,'distance'), lty=3, col=ln.col);
   replicates <- nrow(attr(x,'distances'));
   if(type=='points'){
      for(i in 1:ncol(attr(x,'distances')))
	 points(rep(round(attr(x,'subsamples')[i]*attr(x,'selSize')), replicates), attr(x,'distances')[,i], cex=pt.cex, pch=pt.pch, col=pt.col);
   }else{
      stats <- matrix(NA, nrow=7, ncol=ncol(attr(x,'distances')));
      for(i in 1:ncol(attr(x,'distances'))){
	 b <- boxplot.stats(attr(x,'distances')[,i]);
	 points(rep(round(attr(x,'subsamples')[i]*attr(x,'selSize')), length(b$out)), b$out, cex=pt.cex, pch=pt.pch, col=pt.col);
	 stats[, i] <- c(b$conf, b$stats[c(1,5,2,4,3)]);
      }
      x <- round(attr(x,'subsamples')*attr(x,'selSize'))
      for(i in c(1,3,5))
	 polygon(c(x, rev(x)), c(stats[i,], rev(stats[i+1,])), border=NA, col=col);
      lines(x, stats[7,], col=ln.col, lwd=2);
   }
}

summary.enve.GSStest <- function
   ### Summary of an `enve.GSStest` object.
   (object,
   ### `enve.GSStest` object.
   ...
   ### No additional parameters are currently supported.
   ){
   cat('===[ enve.GSStest ]-----------------------\n');
   cat('Alternative hypothesis:\n');
   cat('   The distances in the selection are\n');
   if(attr(object, 'pval.gt') > attr(object, 'pval.lt')){
      cat('   smaller than in the entire dataset\n   (overclustering)\n');
   }else{
      cat('   larger than in the entire dataset\n   (overdispersion)\n');
   }
   p.val <- min(attr(object, 'pval.gt'), attr(object, 'pval.lt'));
   if(p.val==0){
      diff.dist <- attr(object, 'diff.dist');
      p.val.lim <- min(diff.dist[diff.dist>0]);
      cat('\n   P-value <= ', signif(p.val.lim, 4), sep='');
   }else{
      p.val.lim <- p.val;
      cat('\n   P-value: ', signif(p.val, 4), sep='');
   }
   cat(' ', ifelse(p.val.lim<=0.01, "**", ifelse(p.val.lim<=0.05, "*", "")), '\n', sep='');
   cat('------------------------------------------\n');
   cat('call:',as.character(attr(object,'call')),'\n');
   cat('------------------------------------------\n');
}

plot.enve.GSStest <- function
   ### Plots an `enve.GSStest` object.
   (x,
   ### `enve.GSStest` object to plot.
   type=c('overlap', 'difference'),
   ### What to plot. 'overlap' generates a plot of the two contrasting empirical PDFs (to compare against each other),
   ### 'difference' produces a plot of the differences between the empirical PDFs (to compare against zero).
   col='#00000044', col1=col, col2='#44001144', ylab='Probability', xlim=range(attr(x, 'dist.mids')), ylim=c(0,max(c(attr(x, 'all.dist'), attr(x, 'sel.dist')))), ...){
   type <- match.arg(type);
   if(type=='overlap'){
      plot.opts <- list(xlim=xlim, ylim=ylim, ylab=ylab, ..., t='n', x=1);
      do.call(plot, plot.opts);
      bins <- length(attr(x, 'dist.mids'))
      polygon(attr(x, 'dist.mids')[c(1, 1:bins, bins)], c(0,attr(x, 'all.dist'),0), col=col1, border=do.call(rgb, as.list(c(col2rgb(col1)/256, 0.5))));
      polygon(attr(x, 'dist.mids')[c(1, 1:bins, bins)], c(0,attr(x, 'sel.dist'),0), col=col2, border=do.call(rgb, as.list(c(col2rgb(col2)/256, 0.5))));
   }else{
      plot.opts <- list(xlim=range(attr(x, 'diff.mids')), ylim=c(0,max(attr(x, 'diff.dist'))), ylab=ylab, ..., t='n', x=1);
      do.call(plot, plot.opts);
      bins <- length(attr(x, 'diff.mids'));
      polygon(attr(x, 'diff.mids')[c(1, 1:bins, bins)], c(0,attr(x, 'diff.dist'),0), col=col, border=do.call(rgb, as.list(c(col2rgb(col)/256, 0.5))));
   }
}

enve.GSS.merge <- function
   ### Merges two `enve.GSS` objects generated from the same objects at different subsampling levels.
   (x,
   ### First `enve.GSS` object.
   y
   ### Second `enve.GSS` object.
   ){
   # Check consistency
   if(attr(x,'distance') != attr(y,'distance')) stop('Total distances in objects are different.');
   if(any(attr(x,'points') != attr(y,'points'))) stop('Points in objects are different.');
   if(attr(x,'spaceSize') != attr(y,'spaceSize')) stop('Space size in objects are different.');
   if(attr(x,'selSize') != attr(y,'selSize')) stop('Selection size in objects are different.');
   if(attr(x,'dimensions') != attr(y,'dimensions')) stop('Dimensions in objects are different.');
   if(nrow(attr(x,'distances')) != nrow(attr(y,'distances'))) stop('Replicates in objects are different.');
   # Merge
   a <- attr(x,'subsamples');
   b <- attr(y,'subsamples');
   o <- order(c(a,b));
   o <- o[!duplicated(c(a,b)[o])] ;
   d <- cbind(attr(x,'distances'), attr(y,'distances'))[, o] ;
   z <- new('enve.GSS',
      distance=attr(x,'distance'), points=attr(x,'points'),
      distances=d, spaceSize=attr(x,'spaceSize'),
      selSize=attr(x,'selSize'), dimensions=attr(x,'dimensions'),
      subsamples=c(a,b)[o], call=match.call());
   return(z) ;
   ### Returns an `enve.GSS` object.
}

#==============> Define core functions
enve.gss.test <- function
   ### Estimates the empirical difference between distances in a datasets and a subset, and its
   ### statistical significance.
   (dist,
   ### Distances as `dist` object.
   selection,
   ### Selection defining the subset.
   bins=50,
   ### Number of bins to evaluate in the range of distances.
   ...
   ### Any other parameters supported by `enve.gss`, except `subsamples`.
   ){
   s.gss <- enve.gss(dist, selection, subsamples=c(0,1), ...);
   a.gss <- enve.gss(dist, subsamples=c(0,attr(s.gss, 'selSize')/attr(s.gss, 'spaceSize')), ...);
   s.dist <- attr(s.gss, 'distances')[, 2];
   a.dist <- attr(a.gss, 'distances')[, 2];
   range <- range(c(s.dist, a.dist));
   a.f <- hist(a.dist, breaks=seq(range[1], range[2], length.out=bins), plot=FALSE);
   s.f <- hist(s.dist, breaks=seq(range[1], range[2], length.out=bins), plot=FALSE);
   zp.f <- c(); zz.f <- 0; zn.f <- c();
   p.x <- a.f$counts/sum(a.f$counts);
   p.y <- s.f$counts/sum(s.f$counts);
   for(z in 1:length(a.f$mids)){
      zn.f[z] <- 0;
      zz.f <- 0;
      zp.f[z] <- 0;
      for(k in 1:length(a.f$mids)){
         if(z < k){
	    zp.f[z] <- zp.f[z] + p.x[k]*p.y[k-z];
	    zn.f[z] <- zn.f[z] + p.x[k-z]*p.y[k];
	 }
	 zz.f <- zz.f + p.x[k]*p.y[k];
      }
   }
   return(new('enve.GSStest',
      pval.gt=sum(c(zz.f, zp.f)), pval.lt=sum(c(zz.f, zn.f)),
      all.dist=p.x, sel.dist=p.y, diff.dist=c(rev(zn.f), zz.f, zp.f),
      dist.mids=a.f$mids, diff.mids=seq(diff(range(a.f$mids)), -diff(range(a.f$mids)), length.out=1+2*length(a.f$mids)),
      call=match.call()));
   ### Returns an `enve.GSStest` object.
}

enve.gss <- function
   ### Subsample any objects in "distance space" to reduce the effect of sample-clustering.
   ### This function was originally designed to subsample genomes in "phylogenetic distance
   ### space", a clear case of strong clustering bias in sampling, by Luis M. Rodriguez-R
   ### and Michael R Weigand.
   (dist,
   ### Distances as a `dist` object.
   selection=labels(dist),
   ### Objects to include in the subsample. By default, all objects are selected.
   replicates=1000,
   ### Number of replications per point
   summary.fx=median,
   ### Function to summarize the distance distributions in a given replicate. By
   ### default, the median distance is estimated.
   dist.method='euclidean',
   ### Distance method between random points and samples. See `dist`.
   subsamples=seq(0,1,by=0.01),
   ### Subsampling fractions
   dimensions=floor(length(selection)*0.05),
   ### Dimensions to use in the NMDS. By default, 5% of the selection length.
   metaMDS.opts=list(),
   ### Any additional options to pass to metaMDS, as `list`.
   threads=2,
   ### Number of threads to use.
   verbosity=1,
   ### Verbosity. Use 0 to run quietly, increase for additional information.
   points,
   ### Optional. If passed, the MDS step is skipped and this object is used instead.
   ### It can be the `$points` slot of class `metaMDS` (from `vegan`). It must be a
   ### matrix or matrix-coercible object, with samples as rows and dimensions as
   ### columns.
   pre.gss
   ### Optional. If passed, the points are recovered from this object (except if
   ### `points` is also passed. This should be an `enve.GSS` object estimated on the
   ### same objects (the selection is unimportant).
   ){
   if(!is(dist, 'dist')) stop('`dist` parameter must be a `dist` object.');
   if(!require(parallel, quietly=TRUE)) stop('Unavailable required package: `parallel`.');
   # 1. NMDS
   if(missing(points)){
      if(missing(pre.gss)){
	 if(verbosity > 0) cat('===[ Estimating NMDS ]\n');
	 if(!require(vegan, quietly=TRUE)) stop('Unavailable required package: `vegan`.');
	 mds.args <- c(metaMDS.opts, list(comm=dist, k=dimensions, trace=verbosity));
	 points <- do.call(metaMDS, mds.args)$points;
      }else{
	 points <- attr(pre.gss, 'points');
	 dimensions <- ncol(points);
      }
   }else{
      points <- as.matrix(points);
      dimensions <- ncol(points);
   }
   # 2. Pad ranges
   if(verbosity > 0) cat('===[ Padding ranges ]\n');
   dots <- matrix(NA, nrow=nrow(points), ncol=dimensions, dimnames=list(rownames(points), 1:dimensions));
   selection <- selection[!is.na(match(selection, rownames(dots)))];
   for(dim in 1:dimensions){
      dimRange <- range(points[,dim]) + c(-1,1)*diff(range(points[,1]))/length(selection);
      dots[, dim] <- (points[,dim]-dimRange[1])/diff(dimRange);
   }
   # 2. Select points and summarize distances
   if(verbosity > 0) cat('===[ Sub-sampling ]\n');
   distances <- matrix(NA, nrow=replicates, ncol=length(subsamples), dimnames=list(1:replicates, as.character(subsamples)));
   cl <- makeCluster(threads);
   for(frx in subsamples){
      if(verbosity > 1) cat('Sub-sampling at ',(frx*100),'%\n',sep='');
      distances[, as.character(frx)] = parSapply(cl, 1:replicates, enve.__gss,
	 frx, match(selection, rownames(dots)), dimensions, dots, dist.method, summary.fx, dist);
   }
   stopCluster(cl);
   # 3. Build object and return
   return(new('enve.GSS',
      distance=do.call(summary.fx, list(as.matrix(dist)[selection, selection])),
      points=points, distances=distances, spaceSize=nrow(points), selSize=length(selection),
      dimensions=dimensions, subsamples=subsamples, call=match.call()));
   ### Returns an `enve.GSS` object.
}

enve.__gss <- function
   ### Internal ancilliary function (see `enve.gss`).
   (rep, frx, selection, dimensions, dots, dist.method, summary.fx, dist){
   sample <- c();
   if(frx==0) return(0);
   for(point in 1:round(frx*length(selection))){
      rand.point <- runif(dimensions);
      closest.dot <- '';
      closest.dist <- Inf;
      for(dot in selection){
	 dot.dist <- as.numeric(dist(matrix(c(rand.point, dots[dot,]), nrow=2, byrow=TRUE), method=dist.method));
	 if(dot.dist < closest.dist){
	    closest.dot <- dot;
	    closest.dist <- dot.dist;
	 }
      }
      sample <- c(sample, closest.dot);
   }
   return( do.call(summary.fx, list(as.matrix(dist)[sample, sample])) );
}


