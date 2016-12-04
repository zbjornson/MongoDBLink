# MongoDBLink
MongoDB driver for Mathematica

A fast client for MongoDB, built on the official MongoDB java driver.

## Quick setup

This will install the package in the `$AddOnsDirectory`. You may prefer `$UserAddOnsDirectory` instead.

```Mathematica
tmp = URLSave["https://raw.githubusercontent.com/zbjornson/MongoDBLink/master/MongoDBLink.zip"];
dest = FileNameJoin[{$AddOnsDirectory, "Applications"}];
ExtractArchive[tmp, dest];
DeleteFile[tmp];
Print["Installed MongoDBLink to " <> dest]
```

## Usage

**New** docs at http://zbjornson.github.io/MongoDBLink. These are incomplete and
there are some interactivity bugs. When the docs are complete I will also
distribute them with this package.

All symbols have usage text accessible with `?symbol`, and `Options[symbol]`. Quick tutorial:

```Mathematica
(* Load the package *)
<< MongoDBLink`

(* Connect to server. The server must already be running. *)
conn = OpenConnection[];
(* Also supported:
    OpenConnection["mongodb://..."]
    OpenConnection["host", port]
    OpenConnection["host", port, "username", "password", "database"]
*)

(* List databases. *)
DatabaseNames[conn]

(* Get a database *)
db = GetDatabase[conn, "name"]

(* List collections *)
CollectionNames[db]

(* Get a collection *)
coll = GetCollection[db, "name"]

(* Add some example data. The return value is the number of documents modified,
   which is 0 for an insert. *)
InsertDocument[coll, {"a" -> 1, "b" -> 2}]
(* Batch inserts: *)
docs = {"a" -> #, "b" -> 2 #} &/@ Range[5];
InsertDocument[coll, docs]

(* Fetch all documents *)
FindDocuments[coll]

(* Limit the fields returned *)
FindDocuments[coll, "Fields" -> {"b"}]

(* Paginate results *)
FindDocuments[coll, "Offset"->1, "Limit"->1]

(* Use query operators. Refer to the MongoDB docs for info on valid operators. *)
FindDocuments[coll, {"a" -> {"$gt" -> 2}}]

(* Some Wolfram Query operators are transparently executed on the database server: *)
coll[Total, "a"]
coll[Min, "a"]
coll[Max, "a"]
coll[Mean, "a"]

coll[;;3]
coll[2;;3, {"a"}]

(* Any operator will work, but any other than those listed above effectively
   fetch ALL data and convert it to a Dataset for calculation. *)

(* Find distinct values of a field *)
FindDistinct[coll, "b"]
FindDistinct[coll, "b", {"a" -> {"$gt" -> {2}}}]

(* Count documents *)
CountDocuments[coll]
CountDocuments[coll, {"b" -> 2}]

(* Delete documents *)
DeleteDocument[coll, {"a" -> 3}]

(* Update or "upsert" documents. Note that without $set, the entire document
   will be replaced with the new document. *)
UpdateDocument[coll, {"a" -> 4}, {"$set" -> {"a" -> -4}}]

(* When inserting documents with an _id property and making queries against _id
   fields, by default, values are automatically converted to ObjectIds. This can
   be disabled with the option "ConvertIds" -> False. *)

(* Create an ObjectId. Use this when you want to use an ObjectId for a field
   with a key name other than _id. Per above, _id fields are automatically
   converted by default. *)
oid = ObjectId[] (* random ObjectId *)
oid = ObjectId["5849bb55ee320f0abc87b06b"] (* from a valid string *)

(* Cleanup stuff *)
DropCollection[coll];
DropDatabase[db] (* or DropDatabase[conn, "name"] *)
CloseConnection[conn];
```
