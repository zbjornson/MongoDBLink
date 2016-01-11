(* Mathematica Package *)

(* Author: Zach Bjornson *)

BeginPackage["MongoDBLink`", {"JLink`"}]

OpenConnection::usage=
"OpenConnection[] opens a MongoDB connection to localhost:27017.
OpenConnection[host, port] opens a connection to the specified host and port.
The database server must already be running; this function will not start the server.";

DatabaseNames::usage=
"DatabaseNames[connection] lists database names.";

CloseConnection::usage=
"CloseConnection[connection] closes the connection.";

GetDatabase::usage=
"GetDatabase[connection, database] returns the database object.";

DropDatabase::usage=
"DropDatabase[connection, databaseName] drops a database by name.
DropDatabase[database] drops a database.";

CollectionNames::usage=
"CollectionNames[database] returns a list of collection names.";

GetCollection::usage=
"GetCollection[database, collectionName] gets or creates the specified collection by name.";

DropCollection::usage=
"DropCollection[collection] drops a collection.";

(* InputForm formatted *)
Collection::usage="Collection[] is an object that represents a MongoDB collection. Some Dataset \!\(\*ButtonBox[\"Query \",
BaseStyle->\"Hyperlink\",
ButtonData->{\"Documentation/English/System/ReferencePages/Symbols/Query.nb\", None}]\) operators are executed in the database:
\!\(\*
StyleBox[\"collection\",\nFontSlant->\"Italic\"]\)[\!\(\*
StyleBox[\"m\",\nFontSlant->\"Italic\"]\);;\!\(\*
StyleBox[\"n\",\nFontSlant->\"Italic\"]\)], \!\(\*
StyleBox[\"collection\",\nFontSlant->\"Italic\"]\)[;;\!\(\*
StyleBox[\"n\",\nFontSlant->\"Italic\"]\)], \!\(\*
StyleBox[\"collection\",\nFontSlant->\"Italic\"]\)[m;;] for taking a set of rows (1-indexed).
\!\(\*
StyleBox[\"collection\",\nFontSlant->\"Italic\"]\)[\!\(\*
StyleBox[\"i\",\nFontSlant->\"Italic\"]\)] for taking a specific row (1-indexed).
\!\(\*
StyleBox[\"collection\",\nFontSlant->\"Italic\"]\)[\!\(\*
StyleBox[\"m\",\nFontSlant->\"Italic\"]\);;\!\(\*
StyleBox[\"n\",\nFontSlant->\"Italic\"]\), {\"\!\(\*
StyleBox[\"key\",\nFontSlant->\"Italic\"]\)\"}] for taking the contents of a specific column.
\!\(\*
StyleBox[\"collection\",\nFontSlant->\"Italic\"]\)[Total, \"\!\(\*
StyleBox[\"key\",\nFontSlant->\"Italic\"]\)\"] for totaling the contents of a specified column.
\!\(\*
StyleBox[\"collection\",\nFontSlant->\"Italic\"]\)[Mean, \"\!\(\*
StyleBox[\"key\",\nFontSlant->\"Italic\"]\)\"] for finding the mean of a specified column.
\!\(\*
StyleBox[\"collection\",\nFontSlant->\"Italic\"]\)[Min, \"\!\(\*
StyleBox[\"key\",\nFontSlant->\"Italic\"]\)\"] for finding the minimum of a specified column.
\!\(\*
StyleBox[\"collection\",\nFontSlant->\"Italic\"]\)[Max, \"\!\(\*
StyleBox[\"key\",\nFontSlant->\"Italic\"]\)\"] for finding the maximum of a specified column.
\!\(\*
StyleBox[\"collection\",\nFontSlant->\"Italic\"]\)[Dataset] returns a Dataset form of the collection. Use options like \"Fields\" -> {\"key1\"} to limit the data returned.
\!\(\*
StyleBox[\"collection\",\nFontSlant->\"Italic\"]\)[\!\(\*
StyleBox[SubscriptBox[\"operator\", \"1\"],\nFontSlant->\"Italic\"]\), \!\(\*
StyleBox[SubscriptBox[\"operator\", \"2\"],\nFontSlant->\"Italic\"]\), ...] fetch a dataset and then perform the query operators; for large collections and repeated queries it is best to store the Dataset first."

FindDocuments::usage=
"FindDocuments[collection] returns all documents from the collection.
FindDocuments[collection, query] selects documents that satisfy the query.";

CountDocuments::usage=
"CountDocuments[collection] returns the number of documents in the collection.
CountDocuments[collection, query] returns the number of documents that satisfy the query.";

FindDistinct::usage=
"FindDistinct[collection, key] returns a list of unique values of the specified key.
FindDistinct[collection, key, query] returns a list of unique values of the specified key from documents that satisfy the query."

InsertDocument::usage=
"InsertDocument[collection, document] inserts a document (list of rules) into a collection.";

UpdateDocument::usage=
"UpdateDocument[collection, query, update] updates (or upserts) a document (list of rules) in a collection.";

DeleteDocument::usage=
"DeleteDocument[collection, query] deletes document(s) matching the query."

ObjectId::usage=
"ObjectId[] creates a new random ObjectId.
ObjectId[hexstring] creates an ObjectId with the specified hex string.
When performing queries, _id fields are automatically converted to ObjectId. Use this when fields other than _id are of type ObjectId.";

DatabaseConnection
Database
Collection

Begin["`Private`"]

$debug = True;

$rulepattern = {(_Rule | _RuleDelayed)..};


DatabaseConnection /:
  Format[DatabaseConnection[host_String, port_Integer, connection_]] :=
  Block[{DatabaseConnection},
    DatabaseConnection[Panel[Column[{
      Row[{Style["Host: ", Gray], host <> ":" <> ToString[port]}]
    }], FrameMargins -> 5]]
  ]

DatabaseConnection /: DatabaseConnection[host_String, port_Integer, connection_]["connection"] := connection

OpenConnection[] := OpenConnection["localhost", 27017]

OpenConnection[host_String, port_Integer] := Block[{},
  InstallJava[];
  LoadClass["com.mongodb.WriteConcern"];
  DatabaseConnection[host, port, JavaNew["com.mongodb.MongoClient", host, port]]
]

CloseConnection[connection_DatabaseConnection] :=
  JavaBlock[connection["connection"]@close[]; connection]

DatabaseNames[conn_DatabaseConnection] :=
  JavaBlock[conn["connection"]@getDatabaseNames[]@toArray[]]

Database /:
  Format[Database[name_String, db_]] :=
  Block[{Database},
    Database[Panel[Column[{
      Row[{Style["Name: ", Gray], name}]
    }], FrameMargins -> 5]]
  ]

Database /: Database[name_String, db_]["db"] := db

GetDatabase[connection_DatabaseConnection, database_String] := 
  Database[database, connection["connection"]@getDB[database]];

DropDatabase[connection_DatabaseConnection, database_String] :=
  (connection["connection"]@dropDatabase[database]; database)

DropDatabase[database_Database] :=
  With[
    {name = database["db"]@getName[]},
    database["db"]@dropDatabase[];
    name
  ]

CollectionNames[database_Database] :=
  database["db"]@getCollectionNames[]@toArray[]

GetCollection[database_Database, collection_String] :=
  Collection[collection, database["db"]@getCollection[collection]];

DropCollection[collection_Collection] :=
  With[
    {name=collection["collection"]@getName[]},
    collection["collection"]@drop[];
    name
  ]


Collection /: 
  Format[Collection[name_String, collection_]] :=
  Block[{Collection},
    Collection[Panel[Column[{
      Row[{Style["Name: ", Gray], name}]
    }], FrameMargins -> 5]]
  ]

Collection /: Collection[name_String, collection_]["collection"] := collection

(* Dataset-like Query support *)
Collection /: Collection[name_String, collection_][offset_Integer ;; All] :=
  FindDocuments[Collection[name, collection], "Offset" -> offset - 1]

Collection /: Collection[name_String, collection_][offset_Integer ;; end_Integer] /; (end - offset + 1 > 0) :=
  FindDocuments[Collection[name, collection], "Offset" -> offset - 1, "Limit" -> (end - offset + 1)]

Collection /: Collection[name_String, collection_][offset_Integer ;; end_Integer] :=
  Message[Part::take, offset, end - offset + 1, Collection[name, collection]]

Collection /: Collection[name_String, collection_][index_Integer] :=
  FindDocuments[Collection[name, collection], "Offset" -> index - 1, "Limit" -> 1]


Collection /: Collection[name_String, collection_][offset_Integer ;; All, fields_List] :=
  FindDocuments[Collection[name, collection], "Offset" -> offset - 1, "Fields" -> fields]

Collection /: Collection[name_String, collection_][offset_Integer ;; end_Integer, fields_List] /; (end - offset + 1 > 0) :=
  FindDocuments[Collection[name, collection], "Offset" -> offset - 1, "Limit" -> (end - offset + 1), "Fields" -> fields]

Collection /: Collection[name_String, collection_][offset_Integer ;; end_Integer, fields_List] :=
  Message[Part::take, offset, end - offset + 1, Collection[name, collection]]

Collection /: Collection[name_String, collection_][index_Integer, field_String] :=
  FindDocuments[Collection[name, collection], "Offset" -> index - 1, "Limit" -> 1, "Fields" -> {field}]

Collection /: Collection[name_String, collection_][index_Integer, fields_List] :=
  FindDocuments[Collection[name, collection], "Offset" -> index - 1, "Limit" -> 1, "Fields" -> fields]

iAggregate[op_, field_, collection_] :=
  JavaBlock@Block[{al},
    al = JavaNew["java.util.ArrayList"];
    al@add[serialize[
      {
        "$group" -> {
          "_id" -> Null,
          "result" -> {op -> "$"<>field}
        }
      }]];
    collection@aggregate[al]@results[]@get[0]@get["result"]
  ]

Collection /: Collection[name_String, collection_][Total, field_String] := iAggregate["$sum", field, collection]
Collection /: Collection[name_String, collection_][Mean, field_String] := iAggregate["$avg", field, collection]
Collection /: Collection[name_String, collection_][Min, field_String] := iAggregate["$min", field, collection]
Collection /: Collection[name_String, collection_][Max, field_String] := iAggregate["$max", field, collection]

Collection /: Collection[name_String, collection_][Dataset, opts:_Rule...] :=
  Dataset[Association /@ FindDocuments[Collection[name, collection], opts]]

(* Passthrough to Dataset Query operators. Can be terribly slow if the collection is large. *)
Collection /: Collection[name_String, collection_][query__] := (If[$debug, Print["Warning: Dataset op"]];
  Dataset[Association /@ FindDocuments[Collection[name, collection]]][query])


(* https://api.mongodb.org/java/3.0/ *)
writeConcernStringToEnum["Acknowledged"] = WriteConcern`ACKNOWLEDGED (* syn: SAFE *)
writeConcernStringToEnum["FSynced"] = WriteConcern`FSYNCED (* syn: FSYNC_SAFE *)
writeConcernStringToEnum["Journaled"] = WriteConcern`JOURNALED (* syn: JOURNAL_SAFE *)
writeConcernStringToEnum["Majority"] = WriteConcern`Majority
writeConcernStringToEnum["Unacknowledged"] = WriteConcern`UNACKNOWLEDGED (* syn: NORMAL *)
writeConcernStringToEnum["ReplicaAcknowledged"] = WriteConcern`REPLICA_ACKNOWLEDGED (* syn: REPLICAS_SAFE*)

Options[InsertDocument] = {"WriteConcern" -> "Acknowledged"};

InsertDocument[collection_Collection, document:$rulepattern, opts:OptionsPattern[]] := JavaBlock@Block[
  {docobj, result, writeconcern},
  docobj = serialize[document];
  writeconcern = writeConcernStringToEnum["WriteConcern" /. {opts} /. Options[InsertDocument]];
  result = collection["collection"]@insert[{docobj}, writeconcern];
  result@getN[]
]



Options[UpdateDocument] = {"WriteConcern" -> "Acknowledged", "Upsert" -> False, "Multi" -> False};

UpdateDocument[collection_Collection, query:$rulepattern|{}, document:$rulepattern, opts:_Rule...] := JavaBlock@Module[
  {qryobj, docobj, result, upsert, writeconcern, multi},
  qryobj = serialize[query];
  docobj = serialize[document];
  writeconcern = writeConcernStringToEnum["WriteConcern" /. {opts} /. Options[UpdateDocument]];
  multi = "Multi" /. {opts} /. Options[UpdateDocument];
  upsert = "Upsert" /. {opts} /. Options[UpdateDocument];
  result = collection["collection"]@update[qryobj, docobj, upsert, multi, writeconcern];
  result@getN[]
]

ObjectId[] := JavaNew["org.bson.types.ObjectId"]
ObjectId[hexstring_String] := JavaNew["org.bson.types.ObjectId", hexstring]



serialize[x : $rulepattern] := serialize[Null, x]

serialize[{}] := JavaNew["com.mongodb.BasicDBObject"]

serialize[_, x : $rulepattern] := Block[
  {newdbobj = JavaNew["com.mongodb.BasicDBObject"]},
  Map[serialize[newdbobj, #] &, x];
  newdbobj
]

serialize[_, x : { $rulepattern }] := Block[
  {newdblist = JavaNew["com.mongodb.BasicDBList"]},
  MapIndexed[newdblist@put[First[#2] - 1, serialize[#]]&, x];
  newdblist
]

(* $in, $nin, ... *)
serialize[dbobj_, Rule["_id", {a_ -> b_}]] := 
  dbobj@put["_id", serialize[dbobj, {a -> (ObjectId /@ b)}]]

serialize[dbobj_, Rule["_id", v_]] /; Instance[v, "org.bson.types.ObjectId"] := 
  dbobj@put["_id", v]

serialize[dbobj_, Rule["_id", Null]] := 
  dbobj@put["_id", Null]

serialize[dbobj_, Rule["_id", v_String]] := 
  dbobj@put["_id", ObjectId[v]]

serialize[dbobj_, Rule[k_String, v_]] := 
  dbobj@put[MakeJavaObject[k], serialize[dbobj, v]]

serialize[dbobj_, {}] := JavaNew["com.mongodb.BasicDBObject"]

serialize[dbobj_, x_] := MakeJavaObject[x] (*:(_Integer|_Real|_String|_List|True|False)*)

serialize[dbobj_, x_?JavaObjectQ] := x



Options[FindDocuments] = {"Limit" -> Infinity, "Offset" -> 0, "Fields" -> All};

(* Automatically optimize Length[FindDocuments[...]] calls *)
(* Does not work. *)
(*Length[FindDocuments[collection_Collection, opts:_Rule...]] ^:= CountDocuments[collection, opts]*)
(*Length[FindDocuments[collection_Collection, query:($rulePattern|{}), opts:_Rule...]] ^:= CountDocuments[collection, query, opts]*)

FindDocuments[collection_Collection, opts:_Rule...] := FindDocuments[collection, {}, opts]

FindDocuments[collection_Collection, query:($rulepattern|{}), opts:_Rule...] := With[
  {
    limit = "Limit" /. {opts} /. Options[FindDocuments],
    offset = "Offset" /. {opts} /. Options[FindDocuments],
    projection = "Fields" /. {opts} /. Options[FindDocuments]
  },
  iFindDocuments[collection, query, projection, offset, limit]
]

iFindDocuments[collection_Collection, query_, projection_, offset_, limitValue_] := (*JavaBlock@*)Block[
  {
    serializedQuery,
    serializedProjection,
    cursor
  },
  LoadClass["MongoDBLinkUtils"];
  serializedQuery = serialize[query];
  cursor = If[projection === All,
    collection["collection"]@find[serializedQuery],
    serializedProjection = serialize[#->1 &/@ projection];
    collection["collection"]@find[serializedQuery, serializedProjection]
  ];
  If[offset != 0, cursor@skip[offset]];
  If[limitValue != Infinity, cursor@limit[limitValue]];
  MongoDBLinkUtils`Iterate[cursor]
]

CountDocuments[collection_Collection] := collection["collection"]@count[]

CountDocuments[collection_Collection, query:($rulepattern|{})] := JavaBlock@Block[
  {
    serializedQuery
  },
  serializedQuery = serialize[query];
  collection["collection"]@count[serializedQuery]
]

FindDistinct[collection_Collection, key_String] := JavaBlock[collection["collection"]@distinct[key]@toArray[]]

FindDistinct[collection_Collection, key_String, query : $rulepattern] := JavaBlock@Block[
  {
    serializedQuery = serialize[query]
  },
  collection["collection"]@distinct[key, serializedQuery]@toArray[]
]


Options[DeleteDocument] = {"WriteConcern" -> "Acknowledged"};
DeleteDocument[collection_Collection, query:($rulepattern|{}), opts:_Rule...] := JavaBlock@Block[
  {
    writeconcern = writeConcernStringToEnum["WriteConcern" /. {opts} /. Options[DeleteDocument]],
    serializedQuery = serialize[query]
  },
  collection["collection"]@remove[serializedQuery, writeconcern]
]

End[]

EndPackage[]

(*System.setProperty("DEBUG.MONGO", "true");
In[18]:= LoadJavaClass["java.util.logging.Logger"]

Out[18]= JLink`JavaClass["java.util.logging.Logger", 18, {
JLink`JVM["vm1"]}, 2, "java`util`logging`Logger`", False, True]

In[25]:= LoadJavaClass["java.util.logging.Level"]

Out[25]= JLink`JavaClass["java.util.logging.Level", 19, {
JLink`JVM["vm1"]}, 2, "java`util`logging`Level`", False, True]

In[19]:= logger = Logger`getLogger["com.mongodb"]

Out[19]= JLink`Objects`vm1`JavaObject269033681190913

In[26]:= logger@setLevel[Level`WARNING]*)