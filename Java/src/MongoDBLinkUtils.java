import org.bson.types.Binary;
import java.io.*;
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

}