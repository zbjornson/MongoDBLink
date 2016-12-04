<<"MongoDBLink/MongoDBLink.m"

BeginTestSection["Tests"]

BeginTestSection["Connection, Database"]

Test[
	MatchQ[
		OpenConnection["mongodb://localhost:27017"],
		DatabaseConnection["mongodb://localhost:27017", _?(InstanceOf[#, "com.mongodb.MongoClient"]&)]]
	,
	True
	,
	TestID->"b12cd126-ae75-4709-ae87-707624adec44"
]

Test[
	connection = OpenConnection[];
	MatchQ[connection, DatabaseConnection["localhost", 27017, _?(InstanceOf[#, "com.mongodb.MongoClient"]&)]]
	,
	True
	,
	TestID->"b12cd126-ae75-4709-ae87-707624affc49"
]

Test[
	InstanceOf[connection["connection"], "com.mongodb.MongoClient"]
	,
	True,
	TestID->"225090f2-5222-45ac-a28f-87ffcca4de4c"
]

Test[
	database = GetDatabase[connection, "test"];
	MatchQ[database, Database["test", _?(InstanceOf[#, "com.mongodb.DB"]&)]]
	,
	True
	,
	TestID->"418d1cd9-56eb-445a-b1e9-d09cb4a8d36b"
]

Test[
	InstanceOf[database["db"], "com.mongodb.DB"]
	,
	True,
	TestID->"8125e923-0c62-4b42-98c9-c81dd45a1010"
]

Test[
	collection1 = GetCollection[database, "test1"];
	MatchQ[collection1, Collection["test1", _?(InstanceOf[#, "com.mongodb.DBCollection"]&)]]
	,
	True
	,
	TestID->"68d394bf-a124-4369-934e-982ce35ef06f"
]

Test[
	InstanceOf[collection1["collection"], "com.mongodb.DBCollection"]
	,
	True
	,
	TestID->"3e1cc4b3-fb2a-44d8-b27c-d81edb450e82"
]

EndTestSection[]

BeginTestSection["Insert, Find"]

Test[
	InsertDocument[collection1, {"a" -> #, "b" -> 2 * #}] & /@ Range[5]
	,
	List[0, 0, 0, 0, 0]
	,
	TestID->"55bb46b4-f1b9-489b-bb31-24fd780bc570"
]

(* Mongo lazily creates stuff, so this has to come after an insert. *)
Test[
	ArrayQ[DatabaseNames[connection]] && MemberQ[DatabaseNames[connection], "test"]
	,
	True
	,
	TestID->"1115abd1-c623-4321-9931-d942f925a01a"
]

Test[
	CollectionNames[database]
	,
	{"test1"}
	,
	TestID->"bdf8ac5c-1f44-4015-ad5f-4fca470677eb"
]

Test[
	CountDocuments[collection1]
	,
	5
	,
	TestID->"57985420-541b-479e-8c7f-0bb1da0f202c"
]

Test[
	FindDocuments[collection1]
	,
	{{"_id" -> _, "a" -> 1, "b" -> 2}, {"_id" -> _, "a" -> 2, "b" -> 4}, {"_id" -> _, "a" -> 3, "b" -> 6}, {"_id" -> _, "a" -> 4, "b" -> 8}, {"_id" -> _, "a" -> 5, "b" -> 10}}
	,
	TestID->"2ea773c4-8cbd-4526-91e8-ae1e67de70e4"
	,
	SameTest -> MatchQ
]

Test[
	FindDocuments[collection1, "Fields" -> {"b"}]
	,
	{{"_id" -> _, "b" -> 2}, {"_id" -> _, "b" -> 4}, {"_id" -> _, "b" -> 6}, {"_id" -> _, "b" -> 8}, {"_id" -> _, "b" -> 10}}
	,
	TestID->"b0751b9f-7b1a-4ccf-ac53-7a24d470ddd5"
	,
	SameTest -> MatchQ
]

Test[
	MatchQ[FindDocuments[collection1, "Limit" -> 2], {{"_id" -> _, "a" -> 1, "b" -> 2}, {"_id" -> _, "a" -> 2, "b" -> 4}}]
	,
	True
	,
	TestID->"10aad15c-f304-48b5-af95-a74baae598c2"
]

Test[
	MatchQ[FindDocuments[collection1, "Offset" -> 1, "Limit" -> 1], {{"_id" -> _, "a" -> 2, "b" -> 4}}]
	,
	True
	,
	TestID->"494fa114-f280-49de-b9fe-b10ab903ab67"
]

Test[
	collection2 = GetCollection[database, "test2"];
	InsertDocument[collection2, {"a" -> {"b" -> {"c" -> 1}, "d" -> {"e" -> 1}}}];
	FindDocuments[collection2]
	,
	{{"_id" -> _,  "a" -> {"b" -> {"c" -> 1}, "d" -> {"e" -> 1}}}}
	,
	TestID->"b2a0406c-42f0-465d-aaf8-a7f469922704"
	,
	SameTest -> MatchQ
]

Test[
	collection3 = GetCollection[database, "test3"];
	InsertDocument[collection3, {"a" -> 1, "b" -> {{"b1" -> 1}}}];
	FindDocuments[collection3]
	,
	{{"_id" -> _, "a" -> 1, "b" -> {{"b1" -> 1}}}}
	,
	TestID->"738d2377-71a6-4869-ab08-a3349e682f5d"
	,
	SameTest -> MatchQ
]

Test[
	collection3 = GetCollection[database, "test3"];
	InsertDocument[collection3, {
		{"name" -> "doc1"},
		{"name" -> "doc2"},
		{"name" -> "doc3"}
	}];
	FindDocuments[collection3, {"name" -> {"$exists" -> True}}]
	,
	{
		{"_id" -> _, "name" -> "doc1"},
		{"_id" -> _, "name" -> "doc2"},
		{"_id" -> _, "name" -> "doc3"}
	}
	,
	TestID->"Test-20161208-G9J0E2"
	,
	SameTest -> MatchQ
]

EndTestSection[]

BeginTestSection["FindDistinct"]



EndTestSection[]

BeginTestSection["Count"]

Test[
	CountDocuments[collection1]
	,
	5
	,
	TestID->"91b4c365-93fe-4e40-92e0-0ff309f8a51f"
]

Test[
	CountDocuments[collection1, {"a" -> {"$gt" -> 2}}]
	,
	3
	,
	TestID->"7432c3eb-6ca7-452c-aae4-03707d6c8f12"
]

EndTestSection[]

BeginTestSection["Update"]

(* TODO *)

EndTestSection[]

BeginTestSection["Delete"]

(* TODO *)

EndTestSection[]

BeginTestSection["Collection Query operators"]

Test[
	collection1[1]
	,
	{{"_id" -> _, "a" -> 1, "b" -> 2}}
	,
	TestID->"db65d77e-942c-4a97-8ca8-bf288a18af28"
	,
	SameTest -> MatchQ
]

Test[
	MatchQ[collection1[1 ;; 3], {{"_id" -> _, "a" -> 1, "b" -> 2}, {"_id" -> _, "a" -> 2, "b" -> 4}, {"_id" -> _, "a" -> 3, "b" -> 6}}]
	,
	True
	,
	TestID->"1fb87aa9-a8cc-4a00-9e7b-0298d900a2bc"
]

Test[
	MatchQ[collection1[ ;; 3], {{"_id" -> _, "a" -> 1, "b" -> 2}, {"_id" -> _, "a" -> 2, "b" -> 4}, {"_id" -> _, "a" -> 3, "b" -> 6}}]
	,
	True
	,
	TestID->"605477cd-f573-4965-b736-44dcc3f00df2"
]

Test[
	collection1[3 ;; ]
	,
	{{"_id" -> _, "a" -> 3, "b" -> 6}, {"_id" -> _, "a" -> 4, "b" -> 8}, {"_id" -> _, "a" -> 5, "b" -> 10}}
	,
	TestID->"8bd30a9f-efb7-45fc-9629-5bcca6751884"
	,
	SameTest -> MatchQ
]

Test[
	collection1[1, "a"]
	,
	{{"_id" -> _, "a" -> 1}}
	,
	TestID->"f7701d71-b9ce-4ecd-9bcd-5e3eda8f135b"
	,
	SameTest -> MatchQ
]

Test[
	collection1[1, List["a"]]
	,
	{{"_id" -> _, "a" -> 1}}
	,
	TestID->"d68e4dc4-794c-4250-855b-1ad3e171ad4b"
	,
	SameTest -> MatchQ
]

Test[
	MatchQ[collection1[Span[1, 3], List["a"]], List[List[Rule["_id", Blank[]], Rule["a", 1]], List[Rule["_id", Blank[]], Rule["a", 2]], List[Rule["_id", Blank[]], Rule["a", 3]]]]
	,
	True
	,
	TestID->"9e033eb2-03da-4eac-b531-472d564496e0"
]

Test[
	MatchQ[collection1[Span[1, 3], List["a"]], List[List[Rule["_id", Blank[]], Rule["a", 1]], List[Rule["_id", Blank[]], Rule["a", 2]], List[Rule["_id", Blank[]], Rule["a", 3]]]]
	,
	True
	,
	TestID->"5caf1185-ef9d-430c-b696-eb3db2dce273"
]

Test[
	MatchQ[collection1[Span[3, All], List["a"]], List[List[Rule["_id", Blank[]], Rule["a", 3]], List[Rule["_id", Blank[]], Rule["a", 4]], List[Rule["_id", Blank[]], Rule["a", 5]]]]
	,
	True
	,
	TestID->"8a0ec73c-d8c4-4cc2-b249-f13c1d0608e3"
]

Test[
	Head[collection1[Dataset]]
	,
	Dataset
	,
	TestID->"6fdd52a9-33d7-4481-975c-a711cc6c244d"
]

Test[
	collection1[Total, "a"]
	,
	15
	,
	TestID->"d28103f8-bc9c-4c81-8414-f020966ecd06"
]

Test[
	collection1[Mean, "a"]
	,
	3.`
	,
	TestID->"fc43d5af-27ae-43f8-9cad-152787162acb"
]

Test[
	collection1[Max, "a"]
	,
	5
	,
	TestID->"227ff49e-ef69-46fd-9ab5-e215ac407285"
]

Test[
	collection1[Min, "a"]
	,
	1
	,
	TestID->"eb7073c6-82f5-4aea-9581-c5fcf6d16806"
]

EndTestSection[]

BeginTestSection["Serializer"]

Test[
	MongoDBLinkUtils`Serialize[{"_id" -> {"$in" -> {"56838373c68636914452e6f9", "56838373c68636914452e6f0"}}}, True]@toString[]
	,
	"{ \"_id\" : { \"$in\" : [ { \"$oid\" : \"56838373c68636914452e6f9\"} , { \"$oid\" : \"56838373c68636914452e6f0\"}]}}"
	,
	TestID->"317bd836-a18a-4974-95f6-aa04fe4f06aa"
]

Test[
	AddToClassPath["D:\\git\\MongoDBLink\\MongoDBLink\\Java\\"];
	AddToClassPath["D:\\git\\MongoDBLink\\javaOutput\\"];
	LoadJavaClass["MongoDBLinkUtils"];
	MongoDBLinkUtils`Serialize[{"_id" -> ObjectId[]}, True]@toString[]
	,
	"{ \"_id\" : { \"$oid\" : \""~~__~~"\"}}"
	,
	TestID->"17aa32d1-2210-43f0-9235-fe8401074e91"
	,
	SameTest -> StringMatchQ
]

Test[
	AddToClassPath["D:\\git\\MongoDBLink\\MongoDBLink\\Java\\"];
	AddToClassPath["D:\\git\\MongoDBLink\\javaOutput\\"];
	LoadJavaClass["MongoDBLinkUtils"];
	MongoDBLinkUtils`Serialize[{"_id" -> Null}, True]@toString[]
	,
	"{ \"_id\" :  null }"
	,
	TestID->"cfbc40a1-490c-41c7-b233-f0a9f88fa156"
]

Test[
	InstanceOf[MongoDBLinkUtils`Serialize[List[Rule["_id", "56838373c68636914452e6f9"]], True], "com.mongodb.BasicDBObject"]
	,
	True
	,
	TestID->"f67fc346-7c7f-4f7b-b0ed-e18fda0ee458"
]

Test[
	MongoDBLinkUtils`Serialize[List[Rule["a", 3]], True][toString[]]
	,
	"{ \"a\" : 3}"
	,
	TestID->"684553b9-6c28-4b1a-aab7-d1761a5d295c"
]

Test[
	InstanceOf[MongoDBLinkUtils`Serialize[List[], True], "com.mongodb.BasicDBObject"]
	,
	True
	,
	TestID->"179f8b61-f0df-46a4-a20b-592cfc2600c6"
]

Test[
	MongoDBLinkUtils`Serialize[{"a" -> 1, "b" -> {{"b1" -> 1}}}, True]@toString[]
	,
	"{ \"a\" : 1 , \"b\" : [ { \"b1\" : 1}]}"
	,
	TestID->"aa43675c-c925-4450-b221-8cb964194447"
]

EndTestSection[]

Test[
	{DropCollection[collection1], FreeQ[CollectionNames[database], "test1"]}
	,
	{"test1", True}
	,
	TestID->"fceef6f3-34e4-4eb7-8426-d5f3ab02d3d6"
]

Test[
	{DropDatabase[database], FreeQ[DatabaseNames[connection], "test"]}
	,
	{"test", True}
	,
	TestID->"ee57bebd-faaa-4b50-85c9-355b8f2df206"
]

Test[
	Block[{db, coll},
		db = GetDatabase[connection, "test2"];
		coll = GetCollection[db, "test2"];
		InsertDocument[coll, {"a" -> 1}];
		{DropDatabase[connection, "test2"], FreeQ[DatabaseNames[connection], "test2"]}
	]
	,
	{"test2", True}
	,
	TestID->"79b22220-a186-445f-a468-0e50962450f9"
]

Test[
	CloseConnection[connection]
	,
	connection
	,
	TestID->"54141c89-9157-4911-b37a-5e95d34f7d28"
]

Clear[connection, database, collection1, collection2, collection3];

EndTestSection[]
