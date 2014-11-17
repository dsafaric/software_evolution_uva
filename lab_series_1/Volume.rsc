module Volume

import lang::java::jdt::m3::Core;
import lang::java::m3::Core;
import lang::java::m3::AST;
import util::Math;
import Prelude;
import Set;

private loc lcn = |project://smallsql0.21_src|;
public M3 m = createM3FromEclipseProject(lcn);
public loc fl = |java+compilationUnit:///src/Testing.java|;

/*
	============= VOLUME MEASURMENTS =============
*/

public str removeCommentSngLn(loc l){
  f = readFile(l);	
  for (/<S:\/\/.*?\n{1,1}>/s := f){
    f = replaceFirst(f,S,"\n");
  }
  return f;
}

public str removeCommentMlLn(str f){
  for (/<S:\/\*{1,}.*?\*{1,}\/>/s := f){
    f = replaceFirst(f,S,"");
  }
  return f;
}


// the removeTabs function is optional
public str removeTabs(str fileStr){
  for (/<C:\t{1,}>/  := fileStr){
    fileStr = replaceAll(fileStr,C,"");
  }
  return fileStr;  
}

public str removeNwLines(str fileStr){
  for (/<N:\r+>/ := fileStr){	// the pattern matches carrier return regular expressions
    fileStr = replaceAll(fileStr,N,"");	// replaces all of them with ""
  }
  for (/<S:(\n{2,})|(\n+\s+\n+)>/ := fileStr){	// every occurance of either \n\n+ or a white space
    fileStr = replaceFirst(fileStr,S,"\n");		// is replaced by a single new line
  }
  return fileStr;
}

public str fileStr(loc location) = removeNwLines(
									removeCommentMlLn(
									removeTabs(
									removeCommentSngLn(location))));

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

public void LOCProject(){
  int pLOC = 0;
  for (L <- LOCPerFile()){
    println(toList(L.f)[0].file + " LOC: " + toString(L.LN));
    pLOC+=toList(L.LN)[0];
  }
  println("LOC Project: " + toString(pLOC));
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

/*
	============= UNIT MEASURMENTS =============
*/

public list[loc] mths = [mt | mt <- methods(m)];	// global variable of all methods

public list[map [int LOC,loc L]] unitSizeMethods(){
  return [(LOC(mth) : mth) | mth <- mths];
}

public void unitSize(){
  for (u <- sort(unitSizeMethods())){
    println(toList(u.L)[0].file + " LOC: " + toString(u.LOC));
  }
}

alias Complexity = tuple[int level, loc method];

// cyclomatic complexity - need to use the AST and then search for Statements

public set[Declaration] getProjectAst(){
  return {createAstFromFile(f,true,Version = "1.7") | f <- files(m)};
}

public list[Complexity] extractAst(){
  set[Declaration] dcls = getProjectAst();
  list[Complexity] lt = [];
  
  for(d <- dcls){
    Complexity cc = <1,d@src>;
    visit(d){
      case m:\method(_,_,_,_,Statement impl): lt+=<getComplexity(impl),m@src>;
      case m:\method(_,_,_,_): lt+=<1,m@src>;
      case c:\constructor(_,_,_,Statement impl): lt+=<getComplexity(impl),c@src>;
    }
  }
  return lt;
}

public int getComplexity(Statement stat){
  int cc = 1;	// 1 is the default cyclomatic complexity of an unit
  visit(stat){
    case \case(_): cc+=1;
   	case \if(_,_,_): cc+=1;
   	case \if(_,_): cc+=1;
   	case \for(_,_,_): cc+=1;
   	case \for(_,_,_,_): cc+=1;
	case \do(_,_): cc+=1;
	case \foreach(_,_,_): cc+=1;
	case \while(_,_): cc+=1;
	case \try(_,_): cc+=1;
	case \try(_,_,_): cc+=1;
	case \infix(_,str operator,_):{ if (operator == "&&" || operator == "||") cc+=1;}
  }
  return cc;
}
/*public list[Complexity] getCC(){
  list[Complexity] ccLst = [];
  
  for (a <- getUnitAst()){
    Complexity currentComplexity = <1,0>;
    bottom-up-break visit(a){
      case \block(list[Statement] stats): 
        currentComplexity.level+=toInt(sum([countCC(s) | s <- stats]));
      case \switch(_, list[Statement] stats):
        currentComplexity.level+=toInt(sum([countCC(s) | s <- stats]));
    }
    ccLst+=currentComplexity;
  }
  
  
  return ccLst;
}

public num countCC(Statement s){
  visit(s){
      case \case(_): return 1;
   	  case \if(_,_,_): return 1;
   	  case \if(_,_): return 1;
   	  case \for(_,_,_): return 1;
   	  case \for(_,_,_,_): return 1;
	  case \do(_,_): return 1;
	  case \foreach(_,_,_): return 1;
	  case \while(_,_): return 1;
  } //currentComplexity.level+=1;
  return 0;
}*/




public list[num] cyclomaticComplexity(){
  ccs = extractAst();
  return 	[roundEval(size([v.level | v <- ccs, v.level >= 1 && v.level <= 10]),size(ccs)), 
  			roundEval(size([v.level | v <- ccs, v.level >= 11 && v.level <= 20]),size(ccs)), 
  			roundEval(size([v.level | v <- ccs, v.level >= 21 && v.level <= 50]),size(ccs)), 
  			roundEval(size([v.level | v <- ccs, v.level > 50]),size(ccs))];
}

public num roundEval(num v, num s){
   return v;
}

/*public num countStats(Statement stat){
  top-down-break visit(stat){
   	case switchCase(_,_):{
   	  println("Switch");
   	  return 1 + toInt(sum([countStats(s) | s <- stats]));
   	}
   	case \catch(_, Statement body): return 1 + countStats(body);
   	case \do (Statement body, _): return 1 + countStats(body);
   	case \while(_, Statement body): return 1 + countStats(body);
   	case \if (_,thenBranch): return 1 + countStats(thenBranch);
   	case \if (_,tBranch, eBranch): return 1 + countStats(tBranch) + countStats(eBranch);
   	case \for(_,_,_,Statement body): return 1 + countStats(body);
   	case \for(_,_,Statement body): return 1 + countStats(body);
   	case \foreach(_,_,Statement body): return 1 + countStats(body);
  }
  return 0;
}*/

public num countStats2(Statement stat){
  num ccLevel = 1;
  top-down-break visit(stat){
    case \if(_,Statement thenBranch): ccLevel += (1 + countStats2(thenBranch));
    case \if(_,thenBranch,elseBranch): ccLevel += (1 + countStats2(thenBranch)) + (1 + countStats2(elseBranch));
    case \infix("&&",_,_): ccLevel+=1;
    case \infix("||",_,_): ccLevel+=1;
    case \conditional(_,_,_): ccLevel+=1;
    case \for(_,_,_,Statement body): ccLevel+=(1 + countStats2(body));
    case \for(_,_,Statement body): ccLevel+=(1+countStats2(body));
    case \switch(_,list[Statement] stats): ccLevel+=sum([1 + countStats2(s) | s <- stats]);
    case \while(_,Statement body): ccLevel+=(1 + counStats2(body));
    case \do(Statement body,_): ccLevel+=(1 + countStats2(body));
  }
  return ccLevel;
}

