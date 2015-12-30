# MongoDBLink
MongoDB driver for Mathematica

A fast client for MongoDB, built on the official MongoDB java driver.

## Quick setup

This will install the package in the `$UserAddOnsDirectory`. You may prefer `$AddOnsDirectory` instead.

    tmp = URLSave["https://github.com/zbjornson/mathematica-mongodb/archive/master.zip"];
    ExpandArchive[tmp, FileNameJoin[{$UserAddOnsDirectory, "Applications", "MongoDBLink"]];
    DeleteFile[tmp];

Load the package with:

    << MongoDBLink`

See the documentation for usage.

## Developer's guide

Most changes will only require modification of Mathematica code. If you need to modify java code, the build command is:

    // in Java/src/
    javac -d .. -classpath ../mongo-java-driver-3.0.4.jar:/path/to/SystemFiles/Links/JLink/JLink.jar MongoDBLinkUtils.java

replacing `:` with `;` on Windows.

(I'm open for suggestion to improve this. To me this is no more complicated than modifying an Eclipse or NetBeans project classpath.)

Tests live in Tests.wlt and are runnable with TestReport["Tests.wlt"].
