# MongoStore
SessionStore for MongoDB

## Usage

```d
auto database = connectMongoDB("localhost").getDatabase("database");

auto settings = new HTTPServerSettings;
settings.sessionStore = new MongoSessionStore(database);

// In request:

auto session = req.session ? req.session : res.startSession();
session.set("user", Bson(["username": Bson("foo"), "email": Bson("bar@example.com")]));
logInfo("%s", session.get!Bson("user")); // [username: "foo", email: "bar@example.com"]
```
