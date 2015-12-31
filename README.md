# MongoDBLink
MongoDB driver for Mathematica

A fast client for MongoDB, built on the official MongoDB java driver.

## Quick setup

This will install the package in the `$UserAddOnsDirectory`. You may prefer `$AddOnsDirectory` instead.

    tmp = URLSave["https://github.com/zbjornson/mathematica-mongodb/archive/master.zip"];
    ExpandArchive[tmp, FileNameJoin[{$UserAddOnsDirectory, "Applications", "MongoDBLink"]];
    DeleteFile[tmp];

## Usage

Unfortunately I lost my installation of Workbench and can't generate nice docs for now. All symbols have usage text accessible with `?symbol`, and Options[symbol]. Quick tutorial:

    (* Load the package *)
    << MongoDBLink`

    (* Connect to server. The server must already be running. *)
    conn = OpenConnection[]; (* OpenConnection["host", port] also supported. *)

    (* List databases. *)
    DatabaseNames[conn]

    (* Get a database *)
    db = GetDatabase[conn, "name"]

    (* List collections *)
    CollectionNames[db]

    (* Get a collection *)
    coll = GetCollection[db, "name"]

    (* Add some example data. The return value is the number of documents modified, which is 0 for an insert. *)
    InsertDocument[coll, {"a" -> #, "b" -> 2 #}] &/@ Range[5]

    (* Fetch all documents *)
    FindDocuments[coll]

    (* Use query operators. Refer to the MongoDB docs for info on valid operators. *)
    FindDocuments[coll, {"a" -> {"$gt" -> 2}}]

    (* Some Wolfram Query operators are transparently executed on the database server: *)
    coll[Total, "a"]
    coll[Min, "a"]
    coll[Max, "a"]
    coll[Mean, "a"]

    coll[;;3]
    coll[2;;3, {"a"}]

    (* Any operator will work, but any other than those listed above effectively fetch ALL data and convert it to a Dataset for calculation. *)

    (* Find distinct values of a field *)
    FindDistinct[coll, "b"]
    FindDistinct[coll, "b", {"a" -> {"$gt" -> {2}}}]

    (* Count documents *)
    CountDocuments[coll]
    CountDocuments[coll, {"b" -> 2}]

    (* Delete documents *)
    DeleteDocument[coll, {"a" -> 3}]

    (* Update or "upsert" documents. Note that without $set, the entire document will be replaced with the new document. *)
    UpdateDocument[coll, {"a" -> 4}, {"$set" -> {"a" -> -4}}]

    (* Create an ObjectId. When making queries against _id fields, values are automatically converted to ObjectIds. Use this when the key name is something other than _id. *)
    oid = ObjectId[] (* random ObjectId *)
    (* oid = ObjectId["hexstring"] from a valid hex string, which this is not *)

    (* Cleanup stuff *)
    DropCollection[coll];
    DropDatabase[db] (* or DropDatabase[conn, "name"] *)
    CloseConnection[conn];

## Developer's guide

Most changes will only require modification of Mathematica code. If you need to modify java code, the build command is:

    // in Java/src/
    javac -d .. -classpath ../mongo-java-driver-3.0.4.jar:/path/to/SystemFiles/Links/JLink/JLink.jar MongoDBLinkUtils.java

replacing `:` with `;` on Windows.

(I'm open for suggestion to improve this. To me this is less complicated than dealing with an Eclipse or NetBeans project for a project this small.)

Tests live in `Tests.wlt` and are runnable with `TestReport["Tests.wlt"]`.
