
enve.dataframe2dist <- function(
	### Transform a dataframe (or coercible object, like a table) into a `dist` object.
	x,
	### A dataframe (or coercible object) with at least three columns: (1) ID of the object 1,
	### (2) ID of the object 2, and (3) distance between the two objects.
	obj1.index=1,
	### Index of the column containing the ID of the object 1.
	obj2.index=2,
	### Index of the column containing the ID of the object 2.
	dist.index=3
	### Index of the column containing the distance.
	){
   x <- as.data.frame(x);
   ids <- as.character(unique(c(x[,obj1.index], x[,obj2.index])));
   m <- matrix(NA, nrow=length(ids), ncol=length(ids), dimnames=list(ids, ids));
   diag(m) <- 0
   for(i in 1:nrow(x)){
      m[x[i,obj1.index], x[i,obj2.index]] <- x[i,dist.index];
      m[x[i,obj2.index], x[i,obj1.index]] <- x[i,dist.index];
   }
   return(as.dist(m));
   ### Returns a `dist` object.
}

