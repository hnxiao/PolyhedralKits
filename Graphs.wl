(* ::Package:: *)

BeginPackage["GraphTheory`"]

EdmondsMatrix::usage="EdmondsMatrix[g] returns the LHS matrix of Edmonds odd set constraints Mx<=b";
EdmondsVector::usage="EdmondsVector[g] returns the RHS vector of Edmonds odd set constraints Mx<=b";
CycleVertexMatrix::usage="CycleVertexMatrix[g] returns the cycle vertex incidence matrix for both undirected and directed graphs";
CycleEdgeMatrix::usage="CycleEdgeMatrix[g] returns the cycle edge incidence matrix for undirected graphs ONLY";
CycleArcMatrix::usage="CycleArcMatrix[d] returns the cycle arc incidence matrix for directed graphs ONLY";
PreferenceList::usage="PreferenceList[g] returns a random prefrence list";
RothblumMatrix::usage="RothblumMatrix[g,pl] returns the Rothblum stability matrix";
CliqueVertexMatrix::usage="CliqueVertexMatrix[g] returns the clique vertex incidence matrix for graph g";
DominationMatrix::usage="DominationMatrix[g] returns the kernel domination matrix";

DeleteIsomorphicGraphs::usage="DeleteIsomorphicGraphs[gl] removes duplicate graphs under isomorphism";
ImmersionContract::usage="ImmersionContract[d,v] returns the immersion minor of graph d after contracting vertex v";
DeletionDistinctVertexList::usage="DeletionDistinctVertexList[g] returns the deletion-distinct vertices in graph g, where two vertices are deletion-distinct if their removal result in nonisomorphic graphs";
ContractionDistinctVertexList::usage="ContractionDistinctVertexList[g] returns the immersion-distinct vertices in graph d";
DeletionDistinctEdgeList::usage="DeletionDistinctEdgeList[g] returns distinct edges in graph g, the deletion of which result in nonisomorphic graphs";
ContractionDistinctEdgeList::usage="ContractionDistinctEdgeList[g] returns distinct edges in graph g, the constraction of which result in nonisomorphic graphs";
FirstMinorList::usage="FirstMinorList[g] returns all nonisomorphic minors of graph g after one minor operation (vertex deletion, vertex contraction and edge deletion)";
FirstImmersionList::usage="FirstImmersionList[d] returns all nonisomorphic immersions of graph d after one immersion operation (vertex deletion and immersion contraction)";
(*Caution: MinorList and ImmersionList are extremely slow due to their intrinsic computational hard property. 
But for specific problems, minor testing can be done in O(n2).*)
MinorList::usage="MinorList[g] returns all nonisomorphic minors of graph g"; 
ImmersionList::usage="ImmersionList[d] returns all nonisomorphic immersions of digraph d";

ObstructionFreeQ::usage="ObstructionFreeQ[d,obstl] tests whether digraph d is free of obstructions obstl";

FeedbackVertexSetQ::usage="FeedbackVertexSetQ[d,vs] tests whether vertex set vs is a feedback vertex set";
FeedbackVertexSetList::usage="FeedbackVertexSetList[g] returns all minimum feedback vertex sets";

Tournament::usage="Tournament[n] returns a random tournament";
SemiCompleteDigraph::usage="SemiCompleteDigraph[n,m] returns a random semicomplete digraph with m opposite oriented arcs ";

GoodTournament::usage="GoodTournament[n] TRIES to return a strongly connected random tournament without obstructions within 1000 attempts";
GoodSemiCompleteDigraph::usage="GoodSemiCompleteDigraph[n,m] TRIES to return a strongly connected random semicomplete digraph without obstructions within 1000 attempts";
BFSVertexPartition::usage="BFSVertexPartition[d,r] returns a bfs vertex partition with root r. Moreover, each parition is returned in topological order if it is acyclic, otherwise a cycle list in this partition is accompanied";
MaxOutDegreeVertexList::usage="MaxOutDegreeVertexList[d] returns all vertices with maximum out degree";
MinInDegreeVertexList::usage="MinInDegreeVertexList[d] returns all vertices with minimum in degree";
BFSVertexPartitionList::usage="BFSVertexPartitionList[d] returns all bfs vertex partitions rooted at vertices with maximum outdegree by using BFSVertexPartition[d,r]";
HangingCycleList::usage="HangingCycleList[d,v] returns all good distinct cycles incident to vertex v in digrah v";

PossibleDigraphList::usage="PossibleDigraphList[d] returns all possible orientions in a semicomplete digraph with a given supporting structure";


Begin["`Private`"]


(*Graph matrices*)
EdmondsMatrix[g_Graph]:=Module[{el,vl,subl},
	el=EdgeList[g];
	vl=VertexList[g];
	subl=Select[Subsets[vl,{3,Infinity,2}],!EmptyGraphQ[Subgraph[g,#]]&];
	SparseArray[{i_,j_}/;(Length@Intersection[subl[[i]],List@@el[[j]]]==2):>1,{Length@subl,Length@el}]];

EdmondsVector[g_Graph]:=Module[{subl},
	subl=Select[Subsets[VertexList[g],{3,Infinity,2}],!EmptyGraphQ[Subgraph[g,#]]&];
	(Length/@subl-1)/2
];

CycleVertexMatrix[g_Graph]:=Module[{},
	Outer[Boole[MemberQ[Flatten[List@@@#1],#2]]&,FindCycle[g,Infinity,All],VertexList@g,1]];

CycleEdgeMatrix[g_Graph]:=Module[{},
	Outer[Boole[MemberQ[Sort/@#1,#2]]&,FindCycle[g,Infinity,All],EdgeList@g,1]];

CycleArcMatrix[g_Graph]:=Module[{},
	Outer[Boole[MemberQ[#1,#2]]&,FindCycle[g,Infinity,All],EdgeList@g,1]];

PreferenceList[g_Graph]:=Module[{},
	Map[RandomSample[AdjacencyList[g,#]]&,VertexList@g]];

RothblumMatrix[g_Graph,pl_List]:=Module[{el},
	el=List@@@EdgeList@g;
	Outer[Boole[#1==#2\[Or]IntersectingQ[#1,#2]&&
		OrderedQ@{Position[pl[[Intersection[#1,#2][[1]]]],Complement[#2,Intersection[#1,#2]][[1]]],
				Position[pl[[Intersection[#1,#2][[1]]]],Complement[#1,Intersection[#1,#2]][[1]]]}]&,el,el,1]];


(*Graph minors and immersions*)
DeleteIsomorphicGraphs[gl_List]:= Module[{},
	DeleteDuplicates[gl,IsomorphicGraphQ]];

ImmersionContract[d_Graph,v_Integer]:=Module[{vl,el,Nin,Nout,Nio},
	Nin=VertexInComponent[d,{#},1]&;
	Nout=VertexOutComponent[d,{#},1]&;
	Nio=Intersection[Nin@#,Nout@#]&;
	vl=Union[List@#,Nio@#]&@v;
	el=Flatten@Outer[DirectedEdge,Complement[Nin@#,Nio@#],Complement[Nout@#,Nio@#]]&@v;
	EdgeAdd[VertexDelete[d,vl],#]&@Complement[el,EdgeList@d]];

DeletionDistinctVertexList[g_Graph]:= Module[{vl},
	vl=VertexList@g;
	Return[DeleteDuplicates[vl,IsomorphicGraphQ[VertexDelete[g,#1],VertexDelete[g,#2]]&]];];

ContractionDistinctVertexList[d_Graph]:= Module[{vl},
	vl=VertexList@d;
	Return[DeleteDuplicates[vl,IsomorphicGraphQ[ImmersionContract[d,#1],ImmersionContract[d,#2]]&]];];

DeletionDistinctEdgeList[g_Graph]:= Module[{el},
	el=EdgeList@g;
	Return[DeleteDuplicates[el,IsomorphicGraphQ[EdgeDelete[g,#1],EdgeDelete[g,#2]]&]];];

ContractionDistinctEdgeList[g_Graph]:= Module[{el},
	el=EdgeList@g;
	Return[DeleteDuplicates[el,IsomorphicGraphQ[EdgeContract[g,#1],EdgeContract[g,#2]]&]];];

FirstMinorList[g_Graph]:=Module[{dvl,del,cel,fml},
	dvl=DeletionDistinctVertexList@g;
	del=DeletionDistinctEdgeList@g;
	cel=ContractionDistinctEdgeList@g;
	fml=Union[VertexDelete[g,#]&/@dvl,EdgeDelete[g,#]&/@del,EdgeContract[g,#]&/@cel];
	fml=Select[fml,WeaklyConnectedGraphQ];
	fml=Graph/@Select[EdgeList/@fml,UnsameQ[#,{}]&]; (*Delete isolated vertices*)
	DeleteIsomorphicGraphs[fml]];

FirstImmersionList[d_Graph]:=Module[{dvl,cvl,fiml},
	dvl=DeletionDistinctVertexList[d];
	cvl=ContractionDistinctVertexList[d];
	fiml=Union[VertexDelete[d,#]&/@dvl,ImmersionContract[d,#]&/@cvl];
	fiml=Select[fiml,WeaklyConnectedGraphQ];
	fiml=Graph/@Select[EdgeList/@fiml,UnsameQ[#,{}]&]; (*Delete isolated vertices*)
	DeleteIsomorphicGraphs@fiml];

(*Danger zone*)
MinorList[g_Graph]:=Module[{fml,ml},
	fml=FirstMinorList@g;
	ml=NestWhileList[DeleteIsomorphicGraphs@Flatten@Map[FirstMinorList,#]&,fml,UnsameQ[#,{}]&];
	DeleteIsomorphicGraphs@Flatten@ml];
(* Since recursion backtrace is extremely slow in Mma, we use Nest here instead. But a MinorList in recursive way is attached below.
MinorList[g_Graph]:=Module[{},
	Return@DeleteIsomorphicGraphs@Union[#,Flatten@Map[MinorList,#]]&@FirstMinorList[g]];
*)
ImmersionList[d_Graph]:=Module[{fiml,iml},
	fiml=FirstImmersionList@d;
	iml=NestWhileList[DeleteIsomorphicGraphs@Flatten@Map[FirstImmersionList,#]&,fiml,UnsameQ[#,{}]&];
	DeleteIsomorphicGraphs@Flatten@iml];

(*To do*)
(*
SubgraphQ[g,sub]
MinorQ[g,m]
*)



(*Obstruction (induced subgraph) test*)
ObstructionFreeQ[d_Graph,obstl_List]:=Module[{subgl,obstvc},
	obstvc=VertexCount/@obstl;
	subgl=Select[Subgraph[d,#]&/@Subsets[VertexList@d,{Min@obstvc,Max@obstvc}],WeaklyConnectedGraphQ];
(*
	subgl=Select[Subgraph[d,#]&/@Subsets[VertexList@d,MinMax[obstvc]],WeaklyConnectedGraphQ];
*)
	\[Not]Or@@Flatten@Outer[IsomorphicGraphQ,subgl,obstl]];
(*
An interface to function "vf2_subgraph_iso" in Boost graph library (C++),
or "igraph_subisomorphic_lad" or "graph.get.subisomorphisms.vf2" in igraph C library,
or "IGLADFindSubisomorphisms" in IGraphM package
might boost the performance of obstruction test.
*)


(*Feedback Vertex Sets*)
FeedbackVertexSetQ[g_Graph,vs_List]:=Module[{},
	AcyclicGraphQ[Subgraph[#,Complement[VertexList[#],vs]]]&@g];

FeedbackVertexSetList[g_Graph]:=Module[{vsl,fvsl},
	vsl=Subsets[VertexList@g,{#}]&/@Range[VertexCount@g];
	Do[fvsl=Select[vsl[[i]],FeedbackVertexSetQ[g,#]&];
		If[fvsl!={},Return@fvsl],{i,Length@vsl}]
	];


(*Min-Max properties in semicomplete digraphs*)
Tournament[n_Integer]:=Module[{g,t},
	g=CompleteGraph[n];
	t=DirectedGraph[g,"Random",VertexLabels->"Name"]];

SemiCompleteDigraph[n_Integer,m_Integer:1]/;1<=m<=n (n-1)/2:=Module[{t,d,arl},
	t=Tournament[n];
	arl=Reverse/@RandomChoice@Subsets[EdgeList[t],{m}];
	d= EdgeAdd[t,arl]];

GoodTournament[n_Integer]:=Module[{i,t,subgl},
	Do[t=Tournament[n];
		If[ConnectedGraphQ[#]&&ObstructionFreeQ[#,ObstructionList["Tournament"]]&@t,Return[t]],
		{i,1000}]];

GoodSemiCompleteDigraph[n_Integer,m_Integer:1]/;1<=m<=n (n-1)/2:=Module[{i,d,subgl},
	Do[d=SemiCompleteDigraph[n,m];
		If[ConnectedGraphQ[#]&&ObstructionFreeQ[#,ObstructionList["SemiCompleteDigraph"]]&@d,Return[d]],
		{i,1000}]];

BFSVertexPartition[d_Graph,r_Integer]:=Module[{p,vl,vt,ct,vused},
	vt={r}; ct={}; vused=vt; vl=Complement[VertexList@d,vt];
	p=Reap[While[vl!={},
		vt=Complement[#,vused]&@VertexInComponent[d,vt,1];
		AppendTo[vused,#]&/@vt;
		If[AcyclicGraphQ@Subgraph[d,vt],vt=TopologicalSort@Subgraph[d,vt],ct=FindCycle[Subgraph[d,vt],{2,3},All]];
		Sow@{vt,ct};		
		vl=Complement[vl,vt]; ct={}]][[2,1]];
	Prepend[p,{{r},{}}]];

MaxOutDegreeVertexList[d_Graph]:=Module[{},
	Flatten@Position[#,Max[#]]&@VertexOutDegree@d];

MinInDegreeVertexList[d_Graph]:=Module[{},
	Flatten@Position[#,Min[#]]&@VertexInDegree@d];

BFSVertexPartitionList[d_Graph]:=Module[{},
	BFSVertexPartition[d,#]&/@MaxOutDegreeVertexList@d];

HangingCycleList[d_Graph,v_Integer]:=Module[{vl,c2l,c3l,subg,cbad,td,ind},
	ind={};
	c2l=FindCycle[{d,v},{2},All];
	vl=Intersection[VertexInComponent[d,{v},1],VertexOutComponent[d,{v},1]];
	td=VertexDelete[d,Select[vl,UnsameQ[#,v]&]];
	c3l=FindCycle[{td,v},{3},All];
	subg=Subgraph[td,#]&@Union@Flatten[c3l/.DirectedEdge->List];
	cbad=FindCycle[subg,{2},All];
	If[cbad!={},Do[If[Flatten[Intersection[c3l[[i]],#]&/@cbad]!={},AppendTo[ind,i]],{i,Length@c3l}]];
	Union[c2l,Delete[c3l,List/@ind]]];

PossibleDigraphList[dsupp_Graph]:=Module[{el},
	el=DirectedEdge@@@{#,Reverse@#}&/@EdgeList@GraphComplement@UndirectedGraph@dsupp;
	EdgeAdd[dsupp,#]&/@Tuples[el]];


DominationMatrix[g_Graph]:=Module[{},
	Outer[Boole[MemberQ[Flatten[List@@@#1],#2]]&,VertexOutComponent[g,{#},1]&/@VertexList[g],VertexList@g,1]];
CliqueVertexMatrix[g_Graph]:=Module[{},
	Outer[Boole[MemberQ[Flatten[List@@@#1],#2]]&,FindClique[UndirectedGraph@g,Infinity,All],VertexList@g,1]];


End[]


EndPackage[]