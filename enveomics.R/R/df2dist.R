
enve.df2dist <- function(
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
   x[,obj1.index] <- as.character(x[,obj1.index]);
   x[,obj2.index] <- as.character(x[,obj2.index]);
   ids <- unique(c(x[,obj1.index], x[,obj2.index]));
   m <- matrix(NA, nrow=length(ids), ncol=length(ids), dimnames=list(ids, ids));
   diag(m) <- 0
   for(i in 1:nrow(x)){
      m[x[i,obj1.index], x[i,obj2.index]] <- x[i,dist.index];
      m[x[i,obj2.index], x[i,obj1.index]] <- x[i,dist.index];
   }
   return(as.dist(m));
   ### Returns a `dist` object.
}



enve.df2dist.group <- function(
	### Transform a dataframe (or coercible object, like a table) into a `dist` object, where
	### there are 1 or more distances between each pair of objects.
	x,
	### A dataframe (or coercible object) with at least three columns: (1) ID of the object 1,
	### (2) ID of the object 2, and (3) distance between the two objects.
	obj1.index=1,
	### Index of the column containing the ID of the object 1.
	obj2.index=2,
	### Index of the column containing the ID of the object 2.
	dist.index=3,
	### Index of the column containing the distance.
	summary=median,
	### Function summarizing the different distances between the two objects.
	empty.rm=TRUE
	### Remove rows with empty or NA groups
	){
   x <- as.data.frame(x);
   x[,obj1.index] <- as.character(x[,obj1.index]);
   x[,obj2.index] <- as.character(x[,obj2.index]);
   if(empty.rm) x <- x[ !(is.na(x[,obj1.index]) | is.na(x[,obj2.index]) | x[,obj1.index]=='' | x[,obj2.index]==''), ]
   ids <- unique(c(x[,obj1.index], x[,obj2.index]));
   m <- matrix(NA, nrow=length(ids), ncol=length(ids), dimnames=list(ids, ids));
   diag(m) <- 0
   for(i in 2:length(ids)){
      id.i <- ids[i];
      for(j in 1:(i-1)){
	 id.j <- ids[j];
	 d.ij <- summary(c(
	 	x[ x[,obj1.index]==id.i & x[,obj2.index]==id.j, dist.index],
	 	x[ x[,obj2.index]==id.i & x[,obj1.index]==id.j, dist.index] ));
	 m[id.i, id.j] <- d.ij;
	 m[id.j, id.i] <- d.ij;
      }
   }
   return(as.dist(m));
   ### Returns a `dist` object.
}
