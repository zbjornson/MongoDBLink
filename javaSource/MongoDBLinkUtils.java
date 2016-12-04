import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import com.mongodb.*;
import com.wolfram.jlink.*;

class MongoDBLinkUtils {
	public static void Iterate(DBCursor cursor) {
		try {
			KernelLink link = StdLink.getLink();
			link.beginManual();

			// This is imperfect: concurrent writes/deletes will mess this up, and it performs a COUNT
			link.putFunction("List", cursor.size());

			while (cursor.hasNext()) {
				if (link.wasInterrupted()) return;

				DBObject elem = cursor.next();
				Deserialize(link, elem);
			}
		} catch (Exception e) {
			System.out.println("Exception:" + e.toString());
		}
	}

	private static void Deserialize(KernelLink link, DBObject elem) throws MathLinkException {
		@SuppressWarnings("unchecked")
		Map<String, Object> elemMap = elem.toMap();
		link.putFunction("List", elemMap.size());
		for (Map.Entry<String, Object> entry : elemMap.entrySet()) {
			if (elem instanceof BasicDBObject) {
				link.putFunction("Rule", 2);
				link.put(entry.getKey());
			} // otherwise it's a BasicDBList
			Object value = entry.getValue();
			if (value instanceof org.bson.types.ObjectId) {
				link.put(value.toString());
			} else if (value instanceof BasicDBList) {
				Deserialize(link, (BasicDBList) value);
			} else if (value instanceof BasicDBObject) {
				Deserialize(link, (BasicDBObject) value);
			} else {
				link.put(value);
			}
		}
	}

	/**
	 * Serializes a list of documents.
	 * @param expr Mathematica Expr representing a list of list of rules (documents).
	 * @param convertIdFields Automatically convert `_id` values into `ObjectId`s.
	 * @return List of serialized documents.
	 * @throws ExprFormatException
	 * @throws Error 
	 * @throws InterruptedException 
	 */
	public static List<BasicDBObject> SerializeList(Expr expr, boolean convertIdFields) throws ExprFormatException, InterruptedException, Error {
		ArrayList<BasicDBObject> result = new ArrayList<BasicDBObject>();
		int len = expr.length();
		for (int i = 1; i <= len; i++) {
			Expr doc = expr.part(i);
			result.add(Serialize(doc, convertIdFields));
		}
		return result;
	}

	
	/**
	 * Serializes a single document.
	 * @param expr Mathematica Expr representing a List of rules (a document).
	 * @param convertIdFields Automatically convert `_id` values into `ObjectId`s.
	 * @return Serialized document.
	 * @throws ExprFormatException
	 * @throws Error 
	 * @throws InterruptedException 
	 */
	public static BasicDBObject Serialize(Expr expr, boolean convertIdFields) throws ExprFormatException, InterruptedException, Error {
		BasicDBObject result = new BasicDBObject();
		// expr is something like {"a" -> 1, "b" -> "abcd", "c" -> {1, 2, 3}, "d" -> {"d1" -> 1}}
		int len = expr.length();
		for (int i = 1; i <= len; i++) {
			Expr part = expr.part(i);
			if (!part.head().toString().equals("Rule")) {
				throw new Error("All document elements must be rules.");
			}
			String key = part.part(1).asString();
			Expr value = part.part(2);
			if (convertIdFields && key.equals("_id")) {
				result.append(key, ConvertId(value));
			} else {
				result.append(key, SerializePart(value));
			}
		}
		return result;
	}

	private static Object ConvertId(Expr value) throws ExprFormatException, Error, InterruptedException {
		if (value.stringQ()) {
			// hex string
			return new org.bson.types.ObjectId(value.asString());
		} else if (value.symbolQ()) {
			// already an ObjectId, or null
			String strVal = value.asString();
			if (strVal.equals("Null")) {
				return null;
			} else {
				throw new Error("Unhandled _id type: " + strVal);
			}
		} else if (value.listQ()) {
			// Query, e.g. the inner list in {_id -> {$in -> {listOfIds}}
			// I think this the inner list can only ever be length-1?
			Expr values = value.part(1).part(2);
			BasicDBList list = new BasicDBList();
			int listLen = values.length();
			for (int i = 1; i <= listLen; i++) {
				list.add(ConvertId(values.part(i)));
			}
			BasicDBObject obj = new BasicDBObject();
			obj.append(value.part(1).part(1).asString(), list);
			return obj;
		} else if (value.head().toString().equals("ObjectId")) {
			return new org.bson.types.ObjectId(value.part(1).asString());
		} else {
			throw new Error("Unhandled _id type: " + value.asString());
		}
	}

	private static Object SerializePart(Expr value) throws ExprFormatException {
		if (value.realQ()) {
			return value.asDouble();
		} else if (value.stringQ()) {
			return value.asString();
		} else if (value.bigIntegerQ()) {
			// The JLink docs are a bit screwy:
			// .bigIntegerQ = larger than a Java int, but
			// .asBigInteger returns a java.math.BigInteger
			return value.asLong();
		} else if (value.integerQ()) {
			return value.asInt();
		} else if (value.symbolQ()) {
			// There's .trueQ but not .falseQ.
			String strVal = value.asString();
			if (strVal.equals("True")) {
				return true;
			} else if (strVal.equals("False")) {
				return false;
			} else if (strVal.equals("Null")) {
				return null;
			} else {
				throw new Error("Handled type: " + strVal);
			}
			// Any other symbols? Date...
		} else if (value.listQ()) {
			int partLength = value.length();
			if (partLength == 0) {
				return new BasicDBList(); // Ambiguously an object or a list, for Mathematica
			}
			boolean allRules = true;
			boolean anyRules = false;
			for (int i = 1; i <= partLength; i++) {
				boolean isRule = value.part(i).head().toString().equals("Rule"); 
				anyRules |= isRule;
				allRules &= isRule;
			}
			if (anyRules && !allRules) {
				throw new Error("All sub-document elements must be rules.");
			}
			if (allRules) {
				BasicDBObject subdoc = new BasicDBObject();
				for (int i = 1; i <= partLength; i++) {
					Expr rule = value.part(i);
					String key = rule.part(1).asString();
					subdoc.append(key, SerializePart(rule.part(2)));
				}
				return subdoc;
			} else {
				BasicDBList list = new BasicDBList();
				for (int i = 1; i <= partLength; i++) {
					list.add(SerializePart(value.part(i)));
				}
				return list;
			}
		} else {
			throw new Error("Unhandled type: " + value.asString());
		}
	}
}
