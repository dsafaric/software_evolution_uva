// define a regex identifier
// 1. create a M3 model
// 2. get list/set pf al documents in a particular file -> file by file list[set[loc]]
// 3. create AST -> (file loc, readFile(file loc), true, Version = "1.0")
// 4. [model@src | /Expressions model := AST]
// 5. write a function that checkes with string(location string).uri if the docs current is equal to the expression's
// 6. if it is, then move on and check if a documentation's begin.line can be found in an expression's begin line

public M3 getM3(loc location){
  return createM3FromEclipseProject(location);
}

public list[set[loc]] getDocs(M3 model){
  return [model@documentation[f] | f <- files(m)];
}

public list[set[str]] getComments(M3 model){
  list[set[loc]] d = getDocs(model);
}

// [m@src | /Expression m := methodAST]
//createAstFromString(|project://Java_1.0/src/Testing.java|,readFile(|project://Java_1.0/src/Testing.java|),true,Version = "1.0");
// l.end.line
