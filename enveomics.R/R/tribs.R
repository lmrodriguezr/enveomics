
# Use as:
# > # Estimate reference (null) model:
# > tab <- read.table('Ecoli-ML-dmatrix.txt', sep='\t', h=T, row.names=1)
# > dist <- as.dist(tab);
# > all.dist <- enve.tribs(dist);
# > 
# > # Estimate subset (test) model:
# > lee <- read.table('LEE-strains.txt', as.is=T)$V1
# > lee.dist <- enve.tribs(dist, lee, subsamples=seq(0,1,by=0.05), threads=12,
# +    verbosity=2, pre.tribs=all.dist.merge);
# ...
# > 
# > # Plot reference and selection at different subsampling levels:
# > plot(all.dist, t='boxplot');
# > plot(lee, new=FALSE, col='darkred');
# ...
# > 
# > # Test significance of overclustering (or overdispersion):
# > lee.test <- enve.tribs.test(dist, lee, pre.tribs=all.dist.merge,
# +    verbosity=2, threads=12);
# > summary(lee.test);
# > plot(lee.test);
# ...



#==============> Define S4 classes

#' Enveomics: TRIBS S4 Class
#' 
#' Enve-omics representation of "Transformed-space Resampling In Biased Sets
#' (TRIBS)". This object represents sets of distances between objects,
#' sampled nearly-uniformly at random in "distance space". Subsampling
#' without selection is trivial, since both the distances space and the
#' selection occur in the same transformed space. However, it's useful to
#' compare randomly subsampled sets against a selected set of objects. This
#' is intended to identify overdispersion or overclustering (see
#' \code{\link{enve.TRIBStest}}) of a subset against the entire collection of objects
#' with minimum impact of sampling biases. This object can be produced by
#' \code{\link{enve.tribs}} and supports S4 methods \code{plot} and \code{summary}.
#' 
#' @slot distance \code{(numeric)} Centrality measurement of the distances 
#' between the selected objects (without subsampling).
#' @slot points \code{(matrix)}	Position of the different objects in distance
#' space.
#' @slot distances \code{(matrix)} Subsampled distances, where the rows are 
#' replicates and the columns are subsampling levels.
#' @slot spaceSize \code{(numeric)} Number of objects.
#' @slot selSize \code{(numeric)} Number of selected objects.
#' @slot dimensions \code{(numeric)} Number of dimensions in the distance space.
#' @slot subsamples \code{(numeric)} Subsampling levels (as fractions, from 
#' 0 to 1).
#' @slot call \code{(call)} Call producing this object.
#' 
#' @author Luis M. Rodriguez-R [aut, cre]
#' 
#' @exportClass 

enve.TRIBS <- setClass("enve.TRIBS",
                       representation(
                         distance='numeric',
                         points='matrix',
                         distances='matrix',
                         spaceSize='numeric',
                         selSize='numeric',
                         dimensions='numeric',
                         subsamples='numeric',
                         call='call')
                       ,package='enveomics.R'
);

#' Enveomics: TRIBS Test S4 Class
#' 
#' Test of significance of overclustering or overdispersion in a selected
#' set of objects with respect to the entire set (see \code{\link{enve.TRIBS}}). This
#' object can be produced by \code{\link{enve.tribs.test}} and supports S4 methods
#' \code{plot} and \code{summary}.
#' 
#' @slot pval.gt \code{(numeric)}
#' P-value for the overdispersion test.
#' @slot pval.lt \code{(numeric)}
#' P-value for the overclustering test.
#' @slot all.dist \code{(numeric)}
#' Empiric PDF of distances for the entire dataset (subsampled at selection
#' size).
#' @slot sel.dist \code{(numeric)}
#' Empiric PDF of distances for the selected objects (without subsampling).
#' @slot diff.dist \code{(numeric)}
#' Empiric PDF of the difference between \code{all.dist} and \code{sel.dist}. 
#' The p-values are estimating by comparing areas in this PDF greater than and
#' lesser than zero.
#' @slot dist.mids \code{(numeric)}
#' Midpoints of the empiric PDFs of distances.
#' @slot diff.mids \code{(numeric)}
#' Midpoints of the empiric PDF of difference of distances.
#' @slot call \code{(call)}
#' Call producing this object.
#' 
#' @author Luis M. Rodriguez-R [aut, cre]
#' 
#' @exportClass 

enve.TRIBStest <- setClass("enve.TRIBStest",
                           representation(
                             pval.gt='numeric',
                             pval.lt='numeric',
                             all.dist='numeric',
                             sel.dist='numeric',
                             diff.dist='numeric',
                             dist.mids='numeric',
                             diff.mids='numeric',
                             call='call')
                           ,package='enveomics.R'
);

#==============> Define S4 methods

#' Enveomics: TRIBS Summary
#' 
#' Summary of an \code{\link{enve.TRIBS}} object.
#' 
#' @param object
#' \code{\link{enve.TRIBS}} object.
#' @param ...
#' No additional parameters are currently supported.
#' 
#' @author Luis M. Rodriguez-R [aut, cre]
#' 
#' @export 

summary.enve.TRIBS <- function
(object,
 ...
){
  cat('===[ enve.TRIBS ]-------------------------\n');
  cat('Selected',attr(object,'selSize'),'of',
      attr(object,'spaceSize'),'objects in',
      attr(object,'dimensions'),'dimensions.\n');
  cat('Collected',length(attr(object,'subsamples')),'subsamples with',
      nrow(attr(object,'distances')),'replicates each.\n');
  cat('------------------------------------------\n');
  cat('call:',as.character(attr(object,'call')),'\n');
  cat('------------------------------------------\n');
}

#' Enveomics: TRIBS Plot
#' 
#' Plot an \code{\link{enve.TRIBS}} object.
#' 
#' @param x
#' \code{\link{enve.TRIBS}} object to plot.
#' @param new
#' Should a new canvas be drawn?
#' @param type
#' Type of plot. The \strong{points} plot shows all the replicates, the 
#' \strong{boxplot} plot represents the values found by
#' \code{\link[grDevices]{boxplot.stats}}.
#' as areas, and plots the outliers as points.
#' @param col
#' Color of the areas and/or the points.
#' @param pt.cex
#' Size of the points.
#' @param pt.pch
#' Points character.
#' @param pt.col
#' Color of the points.
#' @param ln.col
#' Color of the lines.
#' @param ...
#' Any additional parameters supported by \code{plot}.
#' 
#' @author Luis M. Rodriguez-R [aut, cre]
#' 
#' @export 

plot.enve.TRIBS <- function
(x,
 new=TRUE,
 type=c('boxplot', 'points'),
 col='#00000044',
 pt.cex=1/2,
 pt.pch=19,
 pt.col=col,
 ln.col=col,
 ...
){
  type <- match.arg(type);
  plot.opts <- list(xlim=range(attr(x,'subsamples'))*attr(x,'selSize'),
                    ylim=range(attr(x,'distances')), ..., t='n', x=1);
  if(new) do.call(plot, plot.opts);
  abline(h=attr(x,'distance'), lty=3, col=ln.col);
  replicates <- nrow(attr(x,'distances'));
  if(type=='points'){
    for(i in 1:ncol(attr(x,'distances')))
      points(rep(round(attr(x,'subsamples')[i]*attr(x,'selSize')),
                 replicates), attr(x,'distances')[,i], cex=pt.cex, pch=pt.pch,
             col=pt.col);
  }else{
    stats <- matrix(NA, nrow=7, ncol=ncol(attr(x,'distances')));
    for(i in 1:ncol(attr(x,'distances'))){
      b <- boxplot.stats(attr(x,'distances')[,i]);
      points(rep(round(attr(x,'subsamples')[i]*attr(x,'selSize')),
                 length(b$out)), b$out, cex=pt.cex, pch=pt.pch, col=pt.col);
      stats[, i] <- c(b$conf, b$stats[c(1,5,2,4,3)]);
    }
    x <- round(attr(x,'subsamples')*attr(x,'selSize'))
    for(i in c(1,3,5))
      polygon(c(x, rev(x)), c(stats[i,], rev(stats[i+1,])), border=NA,
              col=col);
    lines(x, stats[7,], col=ln.col, lwd=2);
  }
}

#' Enveomics: TRIBS Summary Test
#' 
#' Summary of an \code{\link{enve.TRIBStest}} object.
#' 
#' @param object
#' \code{\link{enve.TRIBStest}} object.
#' @param ...
#' No additional parameters are currently supported.
#' 
#' @author Luis M. Rodriguez-R [aut, cre]
#' 
#' @export 

summary.enve.TRIBStest <- function
(object,
 ...
){
  cat('===[ enve.TRIBStest ]---------------------\n');
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
  cat(' ', ifelse(p.val.lim<=0.01, "**", ifelse(p.val.lim<=0.05, "*", "")),
      '\n', sep='');
  cat('------------------------------------------\n');
  cat('call:',as.character(attr(object,'call')),'\n');
  cat('------------------------------------------\n');
}

#' Enveomics: TRIBS Plot Test
#' 
#' Plots an \code{\link{enve.TRIBStest}} object.
#' 
#' @param x
#' \code{\link{enve.TRIBStest}} object to plot.
#' @param type
#' What to plot. \code{overlap} generates a plot of the two contrasting empirical
#' PDFs (to compare against each other), \code{difference} produces a plot of the
#' differences between the empirical PDFs (to compare against zero).
#' @param col
#' Main color of the plot if type=\code{difference}.
#' @param col1
#' First color of the plot if type=\code{overlap}.
#' @param col2
#' Second color of the plot if type=\code{overlap}.
#' @param ylab
#' Y-axis label.
#' @param xlim
#' X-axis limits.
#' @param ylim
#' Y-axis limits.
#' @param ...
#' Any other graphical arguments.
#' 
#' @author Luis M. Rodriguez-R [aut, cre]
#' 
#' @export 

plot.enve.TRIBStest <- function
(x,
 type=c('overlap', 'difference'),
 col='#00000044',
 col1=col,
 col2='#44001144',
 ylab='Probability',
 xlim=range(attr(x, 'dist.mids')),
 ylim=c(0,max(c(attr(x, 'all.dist'), attr(x, 'sel.dist')))),
 ...
){
  type <- match.arg(type);
  if(type=='overlap'){
    plot.opts <- list(xlim=xlim, ylim=ylim, ylab=ylab, ..., t='n', x=1);
    do.call(plot, plot.opts);
    bins <- length(attr(x, 'dist.mids'))
    polygon(attr(x, 'dist.mids')[c(1, 1:bins, bins)],
            c(0,attr(x, 'all.dist'),0), col=col1,
            border=do.call(rgb, as.list(c(col2rgb(col1)/256, 0.5))));
    polygon(attr(x, 'dist.mids')[c(1, 1:bins, bins)],
            c(0,attr(x, 'sel.dist'),0), col=col2,
            border=do.call(rgb, as.list(c(col2rgb(col2)/256, 0.5))));
  }else{
    plot.opts <- list(xlim=range(attr(x, 'diff.mids')),
                      ylim=c(0,max(attr(x, 'diff.dist'))), ylab=ylab, ..., t='n', x=1);
    do.call(plot, plot.opts);
    bins <- length(attr(x, 'diff.mids'));
    polygon(attr(x, 'diff.mids')[c(1, 1:bins, bins)],
            c(0,attr(x, 'diff.dist'),0), col=col,
            border=do.call(rgb, as.list(c(col2rgb(col)/256, 0.5))));
  }
}

#' Enveomics: TRIBS Merge
#' 
#' Merges two \code{\link{enve.TRIBS}} objects generated from the same objects at
#' different subsampling levels.
#' 
#' @param x
#' First \code{\link{enve.TRIBS}} object.
#' @param y
#' Second \code{\link{enve.TRIBS}} object.
#' 
#' @return Returns an \code{\link{enve.TRIBS}} object.
#' 
#' @author Luis M. Rodriguez-R [aut, cre]
#' 
#' @export 

enve.TRIBS.merge <- function
(x,
 y
){
  # Check consistency
  if(attr(x,'distance') != attr(y,'distance'))
    stop('Total distances in objects are different.');
  if(any(attr(x,'points') != attr(y,'points')))
    stop('Points in objects are different.');
  if(attr(x,'spaceSize') != attr(y,'spaceSize'))
    stop('Space size in objects are different.');
  if(attr(x,'selSize') != attr(y,'selSize'))
    stop('Selection size in objects are different.');
  if(attr(x,'dimensions') != attr(y,'dimensions'))
    stop('Dimensions in objects are different.');
  if(nrow(attr(x,'distances')) != nrow(attr(y,'distances')))
    stop('Replicates in objects are different.');
  # Merge
  a <- attr(x,'subsamples');
  b <- attr(y,'subsamples');
  o <- order(c(a,b));
  o <- o[!duplicated(c(a,b)[o])] ;
  d <- cbind(attr(x,'distances'), attr(y,'distances'))[, o] ;
  z <- new('enve.TRIBS',
           distance=attr(x,'distance'), points=attr(x,'points'),
           distances=d, spaceSize=attr(x,'spaceSize'),
           selSize=attr(x,'selSize'), dimensions=attr(x,'dimensions'),
           subsamples=c(a,b)[o], call=match.call());
  return(z) ;
}

#==============> Define core functions

#' Enveomics: TRIBS Test
#' 
#' Estimates the empirical difference between all the distances in a set of
#' objects and a subset, together with its statistical significance.
#' 
#' @param dist
#' Distances as \code{dist} object.
#' @param selection
#' Selection defining the subset.
#' @param bins
#' Number of bins to evaluate in the range of distances.
#' @param ...
#' Any other parameters supported by \code{\link{enve.tribs}}, 
#' except \code{subsamples}.
#' 
#' @return Returns an \code{\link{enve.TRIBStest}} object.
#' 
#' @author Luis M. Rodriguez-R [aut, cre]
#' 
#' @export 

enve.tribs.test <- function
(dist,
 selection,
 bins=50,
 ...
){
  s.tribs <- enve.tribs(dist, selection, subsamples=c(0,1), ...);
  a.tribs <- enve.tribs(dist,
                        subsamples=c(0,attr(s.tribs, 'selSize')/attr(s.tribs, 'spaceSize')), ...);
  s.dist <- attr(s.tribs, 'distances')[, 2];
  a.dist <- attr(a.tribs, 'distances')[, 2];
  range <- range(c(s.dist, a.dist));
  a.f <- hist(a.dist, breaks=seq(range[1], range[2], length.out=bins),
              plot=FALSE);
  s.f <- hist(s.dist, breaks=seq(range[1], range[2], length.out=bins),
              plot=FALSE);
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
  return(new('enve.TRIBStest',
             pval.gt=sum(c(zz.f, zp.f)), pval.lt=sum(c(zz.f, zn.f)),
             all.dist=p.x, sel.dist=p.y, diff.dist=c(rev(zn.f), zz.f, zp.f),
             dist.mids=a.f$mids,
             diff.mids=seq(diff(range(a.f$mids)), -diff(range(a.f$mids)),
                           length.out=1+2*length(a.f$mids)),
             call=match.call()));
}

#' Enveomics: TRIBS
#' 
#' Subsample any objects in "distance space" to reduce the effect of
#' sample-clustering. This function was originally designed to subsample
#' genomes in "phylogenetic distance space", a clear case of strong
#' clustering bias in sampling, by Luis M. Rodriguez-R and Michael R
#' Weigand.
#' 
#' @param dist 
#' Distances as a \code{dist} object.
#' @param selection
#' Objects to include in the subsample. By default, all objects are
#' selected.
#' @param replicates
#' Number of replications per point.
#' @param summary.fx
#' Function to summarize the distance distributions in a given replicate. By
#' default, the median distance is estimated.
#' @param dist.method
#' Distance method between random points and samples in the transformed
#' space. See \code{dist}.
#' @param subsamples
#' Subsampling fractions.
#' @param dimensions
#' Dimensions to use in the NMDS. By default, 5\% of the selection length.
#' @param metaMDS.opts
#' Any additional options to pass to metaMDS, as \code{list}.
#' @param threads
#' Number of threads to use.
#' @param verbosity
#' Verbosity. Use 0 to run quietly, increase for additional information.
#' @param points
#' Optional. If passed, the MDS step is skipped and this object is used
#' instead.  It can be the \code{$points} slot of class \code{metaMDS} 
#' (from \code{vegan}).
#' It must be a matrix or matrix-coercible object, with samples as rows and
#' dimensions as columns.
#' @param pre.tribs
#' Optional. If passed, the points are recovered from this object (except if
#' \code{points} is also passed. This should be an \code{\link{enve.TRIBS}} object 
#' estimated on the same objects (the selection is unimportant).
#' 
#' @return Returns an \code{\link{enve.TRIBS}} object.
#' 
#' @author Luis M. Rodriguez-R [aut, cre]
#' 
#' @export

enve.tribs <- function
(dist,
 selection=labels(dist),
 replicates=1000,
 summary.fx=median,
 dist.method='euclidean',
 subsamples=seq(0,1,by=0.01),
 dimensions=ceiling(length(selection)*0.05),
 metaMDS.opts=list(),
 threads=2,
 verbosity=1,
 points,
 pre.tribs
){
  if(!is(dist, 'dist'))
    stop('`dist` parameter must be a `dist` object.');
  # 1. NMDS
  if(missing(points)){
    if(missing(pre.tribs)){
      if(verbosity > 0)
        cat('===[ Estimating NMDS ]\n');
      if(!suppressPackageStartupMessages(
        requireNamespace("vegan", quietly=TRUE)))
        stop('Unavailable required package: `vegan`.');
      mds.args <- c(metaMDS.opts, list(comm=dist, k=dimensions,
                                       trace=verbosity));
      points <- do.call(vegan::metaMDS, mds.args)$points;
    }else{
      points <- attr(pre.tribs, 'points');
      dimensions <- ncol(points);
    }
  }else{
    points <- as.matrix(points);
    dimensions <- ncol(points);
  }
  # 2. Pad ranges
  if(verbosity > 0) cat('===[ Padding ranges ]\n');
  dots <- matrix(NA, nrow=nrow(points), ncol=dimensions,
                 dimnames=list(rownames(points), 1:dimensions));
  selection <- selection[!is.na(match(selection, rownames(dots)))];
  for(dim in 1:dimensions){
    dimRange <- range(points[,dim]) +
      c(-1,1)*diff(range(points[,1]))/length(selection);
    dots[, dim] <- (points[,dim]-dimRange[1])/diff(dimRange);
  }
  # 3. Select points and summarize distances
  if(verbosity > 0) cat('===[ Sub-sampling ]\n');
  distances <- matrix(NA, nrow=replicates, ncol=length(subsamples),
                      dimnames=list(1:replicates, as.character(subsamples)));
  cl <- makeCluster(threads);
  for(frx in subsamples){
    if(verbosity > 1) cat('Sub-sampling at ',(frx*100),'%\n',sep='');
    distances[, as.character(frx)] = parSapply(cl, 1:replicates, enve.__tribs,
                                               frx, match(selection, rownames(dots)), dimensions, dots, dist.method,
                                               summary.fx, dist);
  }
  stopCluster(cl);
  # 4. Build object and return
  return(new('enve.TRIBS',
             distance=do.call(summary.fx, list(as.matrix(dist)[selection, selection])),
             points=points, distances=distances, spaceSize=nrow(points),
             selSize=length(selection), dimensions=dimensions, subsamples=subsamples,
             call=match.call()));
}

#' Enveomics: TRIBS - Internal Ancillary Function
#' 
#' Internal ancillary function (see \code{\link{enve.tribs}}).
#' 
#' @param rep 
#' @param frx 
#' @param selection 
#' @param dimensions 
#' @param dots 
#' @param dist.method 
#' @param summary.fx 
#' @param dist 
#' 
#' @author Luis M. Rodriguez-R [aut, cre]
#' 
#' @export

enve.__tribs <- function
(rep, frx, selection, dimensions, dots, dist.method, summary.fx, dist){
  sample <- c();
  if(frx==0) return(0);
  for(point in 1:round(frx*length(selection))){
    rand.point <- runif(dimensions);
    closest.dot <- '';
    closest.dist <- Inf;
    for(dot in selection){
      dot.dist <- as.numeric(dist(matrix(c(rand.point, dots[dot,]), nrow=2,
                                         byrow=TRUE), method=dist.method));
      if(dot.dist < closest.dist){
        closest.dot <- dot;
        closest.dist <- dot.dist;
      }
    }
    sample <- c(sample, closest.dot);
  }
  return( do.call(summary.fx, list(as.matrix(dist)[sample, sample])) );
}


