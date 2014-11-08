module Volume

import Map;
import List;
import Set;
import String;
import IO;

import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import lang::java::m3::AST;
import Prelude;

public loc lcn = |project://smallsql0.21_src|;
private M3 m = createM3FromEclipseProject(lcn);
public loc file = |java+compilationUnit:///src/Testing.java|;

public set[loc] getDocumentation(loc file){
  return {d | d <- m@documentation[file], size(readFile(d)) > 0};
}

public list[str] getComments(loc file){
  return [readFile(d) | d <- getDocumentation(file)];
}

public str removeComments(loc location){
  f = readFile(location);
  for (c <- getComments(location)){
    f = replaceFirst(f,c,"");
  }
  return f; 
}

private str removeTabs(loc location){
  f = removeComments(location);
  for (/\t/  := f){
    f = replaceFirst(f,"\t","");
  }
  return f;  
}

public str removeNwLines(loc location){
  f = removeTabs(location);
  for (/<N:\n{2,}>/ := f){  // the pattern /<N:\n{2,}>/ check for a sequence of \n greater than 2. So if you have
                            // a case of \n\n\n\n\n or \n\n that will be recognised by the pattern
    f = replaceFirst(f,N,"\n");
  }
  return f;
}

public int linesOfCode(loc location){
  f = removeNwLines(location);
  int c = 0;
  for(/\n/ := f)
    c+=1;
  return c;
}

// top level functions

public list[loc] getFiles(){
  return [l | l <- files(m)];
}

public num linesOfCodeProject(){
  return sum([linesOfCode(l) | l <- getFiles()]);
}
