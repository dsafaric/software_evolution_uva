module Volume

import Map;
import List;
import Set;
import String;
import IO;

import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import lang::java::m3::AST;
import util::Math;
import Set;
import Prelude;

public loc lcn = |project://Java_1.0|;
public M3 m = createM3FromEclipseProject(lcn);
public loc fl = |java+compilationUnit:///src/Testing.java|;

// 1. VOLUME MEASURMENTS

private list[loc] getDocumentation(loc file){
  return[d | d <- m@documentation[file], size(readFile(d)) > 0];
}

private list[str] getComments(loc file){
  return [readFile(d) | d <- getDocumentation(file)];
}

// check for the regex /<C:\/\*{1,}.*?\*{1,}>/ pattern! for removing the rest of the comments!

public str fileStr(loc location) = removeNwLines(removeTabs(removeComments(location)));

private str removeComments(loc location){
  f = readFile(location);
  for (c <- getComments(location)){
    f = replaceFirst(f,c,"");
  }
  return f; 
}

private str removeTabs(str fileStr){
  for (/<C:(\n\t){1,}|(\t\n){1,}>/  := fileStr){
    fileStr = replaceLast(fileStr,C,"\n");
  }
  return fileStr;  
}

public str removeNwLines(str fileStr){
  for (/<N:\n{2,}>/ := fileStr){
    fileStr = replaceFirst(fileStr,N,"\n");
  }
  return fileStr;
}

// get the number of LOC of a single file

public int LOC(loc location){
  f = fileStr(location);
  int c = 0;
  for(/\n/ := f)
    c+=1;
  return c;
}

public list[map[int LN,loc f]] LOCPerFile(){
  return [(LOC(file) : file) | file <- files(m)];
}

// volume measure for the entire project -> LOC measure

public void LOCProject(){
  int pLOC = 0;
  for (L <- LOCPerFile()){
    println(toList(L.f)[0].file + " LOC: " + toString(L.LN));
    pLOC+=toList(L.LN)[0];
  }
  println("LOC Project: " + toString(sum([LOC(l) | l <- files(m)])));
}

// volume measure for the entire project -> Man years measure

public str MY(){
  int pLOC = toInt(sum([LOC(l) | l <- files(m)]));
  return 	((pLOC >= 0 && pLOC <= 66000) ? "Man years 0-8 : Rank ++" : "") +
  			((pLOC >= 66000 && pLOC <= 246000) ? "Man years 8-30 : Rank +" : "") +
  			((pLOC >= 246000 && pLOC <= 665000) ? "Man years 30-80 : Rank o" : "") + 
  			((pLOC >= 665000 && pLOC <= 1310000) ? "Man years 80-160 : Rank -" : "") + 
  			((pLOC >= 1310000) ? "Man years 160 : Rank --" : "");
}

// 2. UNIT SIZE MEASURMENTS

public str getCommentsSingle(str s){	// works perfectly
  for (/<S:\/\/.*?\n{1,1}>/s := s){
    s = replaceFirst(s,S,"\n");
  }
  return s;
}
// /<S:(\/\*{1,}|\*{1,}\/)(.*|\n*)>/m
// grab the content of multi-line comments
public str getCommentsMult(loc location){
  s = readFile(location);
  for (/<S:\/\*{1,}|(.*?\n*?)\*{1,}\/>/ := s){
    s = replaceFirst(s,S,"");
  }
  return s;
}

public list[map [loc L, str C]] getMethods(){
  return [(mth : getCommentsSingle(getCommentsMult(mth))) | mth <- methods(m)];
}
