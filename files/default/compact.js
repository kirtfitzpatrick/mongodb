// This command to be run on replica set nodes one at a time
//
// http://www.mongodb.org/display/DOCS/compact+Command
// Usage: mongo [database] compact.js

assert( rs.isMaster().setName, "not a repl set" );

// we want to compact, but in the background, if we are primary, we must step
// down before compacting
if ( rs.isMaster().ismaster ) {
  // so step down...
  try {
    rs.stepDown();
  } catch(e) {
    print("exception:" + e);
  }

  // after stepdown connections are dropped. do an operation to cause reconnect:
  rs.isMaster();

  // now ready to go.

  // wait for another node to become primary -- it may need data from us for the last
  // small sliver of time, and if we are already compacting it cannot get it while the
  // compaction is running.

  while ( 1 ) {
    var m = rs.isMaster();
    if ( m.ismaster ) {
      print("ERROR: no one took over during our stepDown duration. we are primary again!");
      assert(false);
    }

    if ( m.primary ) break; // someone else is, great

    print("waiting to become secondary");
    sleep(1000);
  }
}

// Paranoid doublecheck here
assert( !rs.isMaster().ismaster, "we are primary, we don't want to compact while we are primary");

// Enable querying on secondary
rs.slaveOk();

// someone else is primary, so we are ready to proceed with a compaction
var collections = db.getCollectionNames();
for (var i=0; i < collections.length; i++) {
  var collection = collections[i];

  print("Compacting " + collection + " collection...");

  print("Stats before:");
  printjson( db[collection].stats() );

  printjson( db.runCommand({ compact:collection, dev:true }) );

  print("Stats after:");
  printjson( db[collection].stats() );
};
