module mongostore;

import vibe.http.session;
import vibe.db.mongo.mongo;
import vibe.db.mongo.database;
import vibe.db.mongo.client;
import vibe.db.mongo.connection;
import vibe.data.bson;
import std.variant;

/// Session class for `HTTPServerSettings.sessionStore`
final class MongoSessionStore : SessionStore
{
public:
	///
	this(string host, string database, string collection = "sessions_")
	{
		_collection = connectMongoDB(host).getDatabase(database)[collection];
	}

	///
	this(MongoClient client, string database, string collection = "sessions_")
	{
		_collection = client.getDatabase(database)[collection];
	}

	///
	this(MongoDatabase database, string collection = "sessions_")
	{
		_collection = database[collection];
	}

	///
	this(MongoCollection collection)
	{
		_collection = collection;
	}

	@property SessionStorageType storageType() const
	{
		return SessionStorageType.bson;
	}

	Session create()
	{
		auto s = createSessionInstance();
		_collection.update(["id" : s.id], Bson(["session" : Bson(null)]), UpdateFlags.Upsert);
		return s;
	}

	Session open(string id)
	{
		return _collection.findOne(["id" : id]).isNull ? Session.init : createSessionInstance(id);
	}

	void set(string id, string key, Variant value)
	{
		_collection.update(["id" : id],
			Bson(["$set" : Bson(["session." ~ key.makeKey : value.get!Bson])]), UpdateFlags.Upsert);
	}

	Variant get(string id, string key, lazy Variant defaultVal)
	{
		auto v = _collection.findOne(["id" : id])["session"].tryIndex(key.makeKey);
		return v.isNull ? defaultVal : Variant(v.get);
	}

	bool isKeySet(string id, string key)
	{
		return !_collection.findOne(Bson(["id" : Bson(id),
			"session." ~ key.makeKey : Bson(["$exists" : Bson(true)])])).isNull;
	}

	void destroy(string id)
	{
		_collection.remove(["id" : id]);
	}

	int iterateSession(string id, scope int delegate(string key) del)
	{
		auto v = _collection.findOne(["id" : id]);
		foreach (string key, _; v["session"])
			if (auto ret = del(key))
				return ret;
		return 0;
	}

private:
	MongoCollection _collection;
}

private string makeKey(string key)
{
	if (key.length == 0)
		return "_";
	if (key[0] == '$')
		return "_" ~ key;
	return key;
}
