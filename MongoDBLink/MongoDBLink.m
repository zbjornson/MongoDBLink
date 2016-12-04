(* ::Package:: *)

(* Mathematica Package *)

(* Author: Zach Bjornson *)

BeginPackage["MongoDBLink`", {"JLink`"}]

OpenConnection::usage=
"OpenConnection[] opens a MongoDB connection to localhost:27017.
OpenConnection[uri] opens a connection to the specified URI.
OpenConnection[host, port] opens a connection to the specified host and port.
OpenConnection[host, port, username, password, database] opens a connection using the specified authentication.
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

Collection::usage="Collection[] represents a MongoDB collection."

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
"InsertDocument[collection, document] inserts a document (list of rules) into a collection.
InsertDocument[collection, documents] inserts a batch of documents (list of list of rules).";

UpdateDocument::usage=
"UpdateDocument[collection, query, update] updates (or upserts) a document (list of rules) in a collection.";

DeleteDocument::usage=
"DeleteDocument[collection, query] deletes document(s) matching the query."

ObjectId::usage=
"ObjectId[] creates a new random ObjectId.
ObjectId[hexstring] creates an ObjectId with the specified hex string.
When performing queries, by default _id fields are automatically converted to ObjectId. Use this when fields other than _id are of type ObjectId.";

DatabaseConnection::usage=
"DatabaseConnection[...] represents a connection to a MongoDB server."

Database::usage=
"Database[...] represents a MongoDB database."


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

DatabaseConnection /:
  Format[DatabaseConnection[uri_String, connection_]] :=
  Block[{DatabaseConnection},
    DatabaseConnection[Panel[Column[{
      Row[{Style["Host: ", Gray], uri}]
    }], FrameMargins -> 5]]
  ]

DatabaseConnection /: DatabaseConnection[uri_String, connection_]["connection"] := connection

OpenConnection[] := OpenConnection["localhost", 27017]

OpenConnection[uri_String] := Block[{mcuri, hosts},
  InstallJava[];
  LoadJavaClass["com.mongodb.WriteConcern"];
  LoadJavaClass["MongoDBLinkUtils"];
  mcuri = JavaNew["com.mongodb.MongoClientURI", uri];
  hosts =
  DatabaseConnection[uri, JavaNew["com.mongodb.MongoClient", mcuri]]
]

OpenConnection[host_String, port_Integer] := Block[{},
  InstallJava[];
  LoadJavaClass["com.mongodb.WriteConcern"];
  LoadJavaClass["MongoDBLinkUtils"];
  DatabaseConnection[host, port, JavaNew["com.mongodb.MongoClient", host, port]]
]

OpenConnection[host_String, port_Integer, "", _, _]:= OpenConnection[host, port]

OpenConnection[host_String, port_Integer, user_String, password_String, database_String] := Module[{al, credential},
  InstallJava[];
  LoadJavaClass["com.mongodb.WriteConcern"];
  LoadJavaClass["com.mongodb.MongoCredential"];
  LoadJavaClass["MongoDBLinkUtils"];
  credential = MongoCredential`createCredential[user, database, MakeJavaObject[password]@toCharArray[]];
  al = JavaNew["java.util.ArrayList"];
  al@add[credential];
  DatabaseConnection[host, port, JavaNew["com.mongodb.MongoClient", JavaNew["com.mongodb.ServerAddress",host, port],al]]
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
    al@add[MongoDBLinkUtils`Serialize[
      {
        "$group" -> {
          "_id" -> Null,
          "result" -> {op -> "$"<>field}
        }
      }, True]];
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

Options[InsertDocument] = {"WriteConcern" -> "Acknowledged", "ConvertIds" -> True};

InsertDocument[collection_Collection, document:$rulepattern, opts:OptionsPattern[]] := JavaBlock@Block[
  {docobj, result, writeconcern, convertIds},
  convertIds = "ConvertIds" /. {opts} /. Options[InsertDocument];
  docobj = MongoDBLinkUtils`Serialize[document, convertIds];
  writeconcern = writeConcernStringToEnum["WriteConcern" /. {opts} /. Options[InsertDocument]];
  result = collection["collection"]@insert[{docobj}, writeconcern];
  result@getN[]
]

InsertDocument[collection_Collection, documents:{($rulepattern)..}, opts:OptionsPattern[]] := JavaBlock@Block[
  {docobjs, result, writeconcern, convertIds},
  convertIds = "ConvertIds" /. {opts} /. Options[InsertDocument];
  docobjs = MongoDBLinkUtils`SerializeList[documents, convertIds];
  writeconcern = writeConcernStringToEnum["WriteConcern" /. {opts} /. Options[InsertDocument]];
  result = collection["collection"]@insert[docobjs, writeconcern];
  result@getN[]
]


Options[UpdateDocument] = {
  "WriteConcern" -> "Acknowledged",
  "Upsert" -> False,
  "Multi" -> False,
  "ConvertIds" -> True
};

UpdateDocument[collection_Collection, query:$rulepattern|{}, document:$rulepattern, opts:_Rule...] := JavaBlock@Module[
  {qryobj, docobj, result, upsert, writeconcern, multi, convertIds},
  convertIds = "ConvertIds" /. {opts} /. Options[UpdateDocument];
  qryobj = MongoDBLinkUtils`Serialize[query, convertIds];
  docobj = MongoDBLinkUtils`Serialize[document, convertIds];
  writeconcern = writeConcernStringToEnum["WriteConcern" /. {opts} /. Options[UpdateDocument]];
  multi = "Multi" /. {opts} /. Options[UpdateDocument];
  upsert = "Upsert" /. {opts} /. Options[UpdateDocument];
  result = collection["collection"]@update[qryobj, docobj, upsert, multi, writeconcern];
  result@getN[]
]


ObjectId[] := ObjectId[JavaNew["org.bson.types.ObjectId"]@toString[]]


Options[FindDocuments] = {
  "Limit" -> Infinity,
  "Offset" -> 0,
  "Fields" -> All,
  "ConvertIds" -> True
};

(* Automatically optimize Length[FindDocuments[...]] calls *)
(* Does not work. *)
(*Length[FindDocuments[collection_Collection, opts:_Rule...]] ^:= CountDocuments[collection, opts]*)
(*Length[FindDocuments[collection_Collection, query:($rulePattern|{}), opts:_Rule...]] ^:= CountDocuments[collection, query, opts]*)

FindDocuments[collection_Collection, opts:_Rule...] := FindDocuments[collection, {}, opts]

FindDocuments[collection_Collection, query:($rulepattern|{}), opts:_Rule...] := With[
  {
    limit = "Limit" /. {opts} /. Options[FindDocuments],
    offset = "Offset" /. {opts} /. Options[FindDocuments],
    projection = "Fields" /. {opts} /. Options[FindDocuments],
    convertIds = "ConvertIds" /. {opts} /. Options[FindDocuments]
  },
  iFindDocuments[collection, query, projection, offset, limit, convertIds]
]

iFindDocuments[collection_Collection, query_, projection_, offset_, limitValue_, convertIds_] := (*JavaBlock@*)Block[
  {
    serializedQuery,
    serializedProjection,
    cursor
  },
  serializedQuery = MongoDBLinkUtils`Serialize[query, convertIds];
  cursor = If[projection === All,
    collection["collection"]@find[serializedQuery],
    serializedProjection = MongoDBLinkUtils`Serialize[#->1 &/@ projection, False];
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
  serializedQuery = MongoDBLinkUtils`Serialize[query, True];
  collection["collection"]@count[serializedQuery]
]

FindDistinct[collection_Collection, key_String] := JavaBlock[collection["collection"]@distinct[key]@toArray[]]

FindDistinct[collection_Collection, key_String, query : $rulepattern] := JavaBlock@Block[
  {
    serializedQuery = MongoDBLinkUtils`Serialize[query, True]
  },
  collection["collection"]@distinct[key, serializedQuery]@toArray[]
]


Options[DeleteDocument] = {"WriteConcern" -> "Acknowledged", "ConvertIds" -> True};

DeleteDocument[collection_Collection, query:($rulepattern|{}), opts:_Rule...] := JavaBlock@Block[
  {
    writeconcern = writeConcernStringToEnum["WriteConcern" /. {opts} /. Options[DeleteDocument]],
    convertIds = "ConvertIds" /. {opts} /. Options[DeleteDocument],
    serializedQuery
  },
  serializedQuery = MongoDBLinkUtils`Serialize[query, convertIds];
  collection["collection"]@remove[serializedQuery, writeconcern]
]

End[]

EndPackage[]
