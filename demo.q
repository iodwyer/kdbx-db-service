// export KDB_LICENSE_B64=IVsWnAIxY1fwF2w9hswMi02r9tNQ8Prz/Yz8D+AnhDYqY5vNSdJfvDF8A75vfr72w/26RzptOKNSTt7WHg+Y5hBr1U5Sd45TIL+za07PSnglKkJ/m6cVk0fNWfwFCiLFnAxV8h3q0x0Zq4Na14ihS1FKxS+W7vbuCNjT9+xGZ3xw2pKx3z29X/iiyZA77NJLvkZKjzoGlJeXfXqZjNaffV7SuylSUT+VzrB1AB2nevnhggUnHYAUn8VnsNWk9lk3dLYRn4TonOn7875ickI7pFQRDt91lmIHZ3SHZCWatXBuxJW6zcDzi4Fus7jGXaP3CTKNIM+iarguJp75X0npP7JsnzMVitXdNyq83fSDHpTo4EYDr+b2GtLnUJ33iW9A3q7qu8g96MtU9DDS7JNddDpw5rHpCunR+uvrsrG/PPmb3b04t3YXVP8ZLfvtXlCCgKinsYZ8iBIpTdzOXMTG4Kp5YPOXXiN7Q0SSkieAnFZWIjGpEkPuEYYOzLxYDgBeYhYE1F5+K1lDkDMaodWmaJLF03k7slxIlQEHxVyIXdr3zoblcb48+gS5cmaxgv5hIQ==

// SETUP 
/ Load module
dbs:use`kx.dbservice_client
/ Create a session (default endpoint: http://localhost:8080)
session:dbs.createSession[]
/ Or specify an endpoint explicitly
session:dbs.createSession["localhost:8080"]

session.listTables[]


// IMPORT WITH CREATE TABLE FLAG
session.importFiles[`table`path`createTable!("fxquote";"fxquote.csv.gz";1b)]
session.querySimple[`table`startTS`endTS`sortCols`limit!(`fxquote;2026.03.02D;2026.03.03D;enlist "ts"; -5)]  
session.describeTable["fxquote"]


// CREATING TABLE MANUALLY
// List tables (empty to begin with)
session.listTables[]

// Define columns
fxquoteCols:(`name`type!("trddate";"date");`name`type!("ts";"timestamp");`name`type`attrMem`attrDisk`attrOrd!("sym";"symbol";"grouped";"parted";"parted");`name`type!("bid";"float");`name`type!("ask";"float"))

// Create partitioned table ('fxquote')
session.createTable`table`type`prtnCol`sortColsDisk`sortColsOrd`columns!("fxquote";"partitioned";"ts";enlist"sym";enlist"sym";fxquoteCols)

// List tables ('fxquote' table returned)
session.listTables[]

// Describe the 'fxquote' table
session.describeTable["fxquote"]



// QUERYING TABLES
// Structured query
session.querySimple([table:"fxquote";startTS:2026.03.02D;endTS:2026.03.03D;sortCols:enlist"ts";limit:5])

// SQL query
session.querySQL([query:"SELECT * FROM fxquote WHERE sym LIKE 'AUD*'"])   // limit doesn't work here

// qSQL query
session.queryQ([query:"select o:first bid,h:max bid,l:min bid,c:last bid by trddate,sym from fxquote"])


// DROP TABLE
session.dropTable["fxquote"]  // Drop the 'fxquote' table



// CREATE TRADE and quote tables
// requires datagen module https://github.com/KxSystems/datagen
([getInMemoryTables; buildPersistedDB]): use `kx.datagen.capmkts
(trade; quote; nbbo; master; exnames): getInMemoryTables[]
buildPersistedDB "data/imports/testdb"
dbmaint:use`kx.dbmaint
// delete all but one date
dbmaint.fnCol[`:data/imports/testdb;`trade;`time;{2026.05.22 + x}]
dbmaint.fnCol[`:data/imports/testdb;`quote;`time;{2026.05.22 + x}]
dbmaint.fnCol[`:data/imports/testdb;`nbbo;`time;{2026.05.22 + x}]

res:session.importKDB([path:"/imports/testdb";mode:"overwrite";createTable:1b])

session.getImport[res`name]  // get status of the import job


res:session.queryQ([query:"(.da.i.dapType;select o:first bid,h:max bid,l:min bid,c:last bid by time.date,sym from quote)";agg:"{x}"])

res:session.queryQ([query:"(.da.i.dapType;cols `quote)";agg:"{x}"])
