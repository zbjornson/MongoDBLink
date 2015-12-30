<< MongoDBLink`

ReinstallJava[CommandLine -> "C:\\Program Files\\Java\\jre1.8.0_40\\bin\\java.exe"];

BeginTestSection["Tests"]

BeginTestSection["Connection, Database"]

connection; database; collection1;

VerificationTest[
	connection = OpenConnection[];
	MatchQ[connection, DatabaseConnection["localhost", 27017, _?(InstanceOf[#, "com.mongodb.MongoClient"]&)]]
	,
	True
	,
	TestID->"b12cd126-ae75-4709-ae87-707624affc49"
]

VerificationTest[
	InstanceOf[connection["connection"], "com.mongodb.MongoClient"]
	,
	True,
	TestID->"225090f2-5222-45ac-a28f-87ffcca4de4c"
]

VerificationTest[
	database = GetDatabase[connection, "test"];
	MatchQ[database, Database["test", _?(InstanceOf[#, "com.mongodb.DB"]&)]]
	,
	True
	,
	TestID->"418d1cd9-56eb-445a-b1e9-d09cb4a8d36b"
]

VerificationTest[
	InstanceOf[database["db"], "com.mongodb.DB"]
	,
	True,
	TestID->"8125e923-0c62-4b42-98c9-c81dd45a1010"
]

VerificationTest[
	collection1 = GetCollection[database, "test1"];
	MatchQ[collection1, Collection["test1", _?(InstanceOf[#, "com.mongodb.DBCollection"]&)]]
	,
	True
	,
	TestID->"68d394bf-a124-4369-934e-982ce35ef06f"
]

VerificationTest[
	InstanceOf[collection1["collection"], "com.mongodb.DBCollection"]
	,
	True
	,
	TestID->"3e1cc4b3-fb2a-44d8-b27c-d81edb450e82"
]

EndTestSection[]

BeginTestSection["Insert, Find"]

VerificationTest[
	Map[Function[InsertDocument[collection1, List[Rule["a", Slot[1]], Rule["b", Times[Slot[1], 2]]]]], Range[5]]
	,
	List[0, 0, 0, 0, 0]
	,
	TestID->"55bb46b4-f1b9-489b-bb31-24fd780bc570"
]

VerificationTest[
	CollectionNames[database]
	,
	{"system.indexes", "test1"}
	,
	TestID->"bdf8ac5c-1f44-4015-ad5f-4fca470677eb"
]

VerificationTest[
	CountDocuments[collection1]
	,
	5
	,
	TestID->"57985420-541b-479e-8c7f-0bb1da0f202c"
]

VerificationTest[
	MatchQ[FindDocuments[collection1], List[List[Rule["_id", Blank[]], Rule["a", 1], Rule["b", 2]], List[Rule["_id", Blank[]], Rule["a", 2], Rule["b", 4]], List[Rule["_id", Blank[]], Rule["a", 3], Rule["b", 6]], List[Rule["_id", Blank[]], Rule["a", 4], Rule["b", 8]], List[Rule["_id", Blank[]], Rule["a", 5], Rule["b", 10]]]]
	,
	True
	,
	TestID->"2ea773c4-8cbd-4526-91e8-ae1e67de70e4"
]

VerificationTest[
	MatchQ[FindDocuments[collection1, Rule["Fields", List["b"]]], List[List[Rule["_id", Blank[]], Rule["b", 2]], List[Rule["_id", Blank[]], Rule["b", 4]], List[Rule["_id", Blank[]], Rule["b", 6]], List[Rule["_id", Blank[]], Rule["b", 8]], List[Rule["_id", Blank[]], Rule["b", 10]]]]
	,
	True
	,
	TestID->"b0751b9f-7b1a-4ccf-ac53-7a24d470ddd5"
]

VerificationTest[
	MatchQ[FindDocuments[collection1, Rule["Limit", 2]], List[List[Rule["_id", Blank[]], Rule["a", 1], Rule["b", 2]], List[Rule["_id", Blank[]], Rule["a", 2], Rule["b", 4]]]]
	,
	True
	,
	TestID->"10aad15c-f304-48b5-af95-a74baae598c2"
]

VerificationTest[
	MatchQ[FindDocuments[collection1, Rule["Offset", 1], Rule["Limit", 1]], List[List[Rule["_id", Blank[]], Rule["a", 2], Rule["b", 4]]]]
	,
	True
	,
	TestID->"494fa114-f280-49de-b9fe-b10ab903ab67"
]

EndTestSection[]

BeginTestSection["FindDistinct"]

VerificationTest[
	Null
	,
	Null
	,
	TestID->"779d880b-784c-4d02-ab3b-72a1d2d8f964"
]

VerificationTest[
	Null
	,
	Null
	,
	TestID->"9a481003-6c15-4a7c-8327-00ab3160efb8"
]

EndTestSection[]

BeginTestSection["Count"]

VerificationTest[
	CountDocuments[collection1]
	,
	5
	,
	TestID->"91b4c365-93fe-4e40-92e0-0ff309f8a51f"
]

VerificationTest[
	CountDocuments[collection1, List[Rule["a", List[Rule["$gt", 2]]]]]
	,
	3
	,
	TestID->"7432c3eb-6ca7-452c-aae4-03707d6c8f12"
]

EndTestSection[]

BeginTestSection["Update"]

EndTestSection[]

BeginTestSection["Delete"]

VerificationTest[
	Null
	,
	Null	
]

EndTestSection[]

BeginTestSection["Collection Query operators"]

VerificationTest[
	MatchQ[collection1[1], List[List[Rule["_id", Blank[]], Rule["a", 1], Rule["b", 2]]]]
	,
	True
	,
	TestID->"db65d77e-942c-4a97-8ca8-bf288a18af28"
]

VerificationTest[
	MatchQ[collection1[Span[1, 3]], List[List[Rule["_id", Blank[]], Rule["a", 1], Rule["b", 2]], List[Rule["_id", Blank[]], Rule["a", 2], Rule["b", 4]], List[Rule["_id", Blank[]], Rule["a", 3], Rule["b", 6]]]]
	,
	True
	,
	TestID->"1fb87aa9-a8cc-4a00-9e7b-0298d900a2bc"
]

VerificationTest[
	MatchQ[collection1[Span[1, 3]], List[List[Rule["_id", Blank[]], Rule["a", 1], Rule["b", 2]], List[Rule["_id", Blank[]], Rule["a", 2], Rule["b", 4]], List[Rule["_id", Blank[]], Rule["a", 3], Rule["b", 6]]]]
	,
	True
	,
	TestID->"605477cd-f573-4965-b736-44dcc3f00df2"
]

VerificationTest[(* FAILURE *)
	MatchQ[collection1[Span[3, All]], List[List[Rule["_id", Blank[]], Rule["a", 3], Rule["b", 6]], List[Rule["_id", Blank[]], Rule["a", 4], Rule["b", 8]], List[Rule["_id", Blank[]], Rule["a", 5], Rule["b", 10]]]]
	,
	True
	,
	TestID->"8bd30a9f-efb7-45fc-9629-5bcca6751884"
]

VerificationTest[
	MatchQ[collection1[1, "a"], List[List[Rule["_id", Blank[]], Rule["a", 1]]]]
	,
	True
	,
	TestID->"f7701d71-b9ce-4ecd-9bcd-5e3eda8f135b"
]

VerificationTest[
	MatchQ[collection1[1, List["a"]], List[List[Rule["_id", Blank[]], Rule["a", 1]]]]
	,
	True
	,
	TestID->"d68e4dc4-794c-4250-855b-1ad3e171ad4b"
]

VerificationTest[
	MatchQ[collection1[Span[1, 3], List["a"]], List[List[Rule["_id", Blank[]], Rule["a", 1]], List[Rule["_id", Blank[]], Rule["a", 2]], List[Rule["_id", Blank[]], Rule["a", 3]]]]
	,
	True
	,
	TestID->"9e033eb2-03da-4eac-b531-472d564496e0"
]

VerificationTest[
	MatchQ[collection1[Span[1, 3], List["a"]], List[List[Rule["_id", Blank[]], Rule["a", 1]], List[Rule["_id", Blank[]], Rule["a", 2]], List[Rule["_id", Blank[]], Rule["a", 3]]]]
	,
	True
	,
	TestID->"5caf1185-ef9d-430c-b696-eb3db2dce273"
]

VerificationTest[(* FAILURE *)
	MatchQ[collection1[Span[3, All], List["a"]], List[List[Rule["_id", Blank[]], Rule["a", 3]], List[Rule["_id", Blank[]], Rule["a", 4]], List[Rule["_id", Blank[]], Rule["a", 5]]]]
	,
	True
	,
	TestID->"8a0ec73c-d8c4-4cc2-b249-f13c1d0608e3"
]

VerificationTest[
	Head[collection1[Dataset]]
	,
	Dataset
	,
	TestID->"6fdd52a9-33d7-4481-975c-a711cc6c244d"
]

VerificationTest[
	collection1[Total, "a"]
	,
	15
	,
	TestID->"d28103f8-bc9c-4c81-8414-f020966ecd06"
]

VerificationTest[
	collection1[Mean, "a"]
	,
	3.`
	,
	TestID->"fc43d5af-27ae-43f8-9cad-152787162acb"
]

VerificationTest[
	collection1[Max, "a"]
	,
	5
	,
	TestID->"227ff49e-ef69-46fd-9ab5-e215ac407285"
]

VerificationTest[
	collection1[Min, "a"]
	,
	1
	,
	TestID->"eb7073c6-82f5-4aea-9581-c5fcf6d16806"
]

EndTestSection[]

BeginTestSection["Serializer"]

VerificationTest[
	MongoDBLink`Private`serialize[List[Rule["_id", List[Rule["$in", List["56838373c68636914452e6f9", "56838373c68636914452e6f0"]]]]]][toString[]]
	,
	"{ \"_id\" : { \"$in\" : [ { \"$oid\" : \"56838373c68636914452e6f9\"} , { \"$oid\" : \"56838373c68636914452e6f0\"}]}}"	
	,
	TestID->"317bd836-a18a-4974-95f6-aa04fe4f06aa"
]

VerificationTest[
	StringMatchQ[MongoDBLink`Private`serialize[{"_id" -> ObjectId[]}]@toString[], "{ \"_id\" : { \"$oid\" : \""~~__~~"\"}}"]
	,
	True
	,
	TestID->"17aa32d1-2210-43f0-9235-fe8401074e91"
]

VerificationTest[
	MongoDBLink`Private`serialize[List[Rule["_id", Null]]][toString[]]
	,
	"{ \"_id\" :  null }"
	,
	TestID->"cfbc40a1-490c-41c7-b233-f0a9f88fa156"
]

VerificationTest[
	InstanceOf[MongoDBLink`Private`serialize[List[Rule["_id", "56838373c68636914452e6f9"]]], "com.mongodb.BasicDBObject"]
	,
	True
	,
	TestID->"f67fc346-7c7f-4f7b-b0ed-e18fda0ee458"
]

VerificationTest[
	MongoDBLink`Private`serialize[List[Rule["a", 3]]][toString[]]
	,
	"{ \"a\" : 3}"
	,
	TestID->"684553b9-6c28-4b1a-aab7-d1761a5d295c"
]

VerificationTest[
	InstanceOf[MongoDBLink`Private`serialize[List[]], "com.mongodb.BasicDBObject"]
	,
	True
	,
	TestID->"179f8b61-f0df-46a4-a20b-592cfc2600c6"
]

VerificationTest[
	With[{a = MongoDBLink`Private`serialize[Null, 1]}, {InstanceOf[a, "java.lang.Integer"], a@toString[]}]
	,
	List[True, "1"]
	,
	TestID->"a1e3781b-f147-4a5d-83b5-2acefb6ba0f4"
]

VerificationTest[
	x = MakeJavaObject[1];
	MongoDBLink`Private`serialize[Null, x] == x
	,
	True
	,
	TestID->"ebd27ef8-953f-433f-9f13-976c2f07ec6c"
]

EndTestSection[]

DropCollection[collection1];

EndTestSection[]
