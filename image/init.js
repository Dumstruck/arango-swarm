
/**
 * This file gets added to /docker-entrypoint-initb.d/_system-init.js
 * which then in turn gets ran by arangodb/arangodb image's entrypoint.sh
 */

db._useDatabase("_system")

/* Do whatever you need to here */

/* Example:
 
if(!db.accounts) {
	db._create("accounts")
}

db.accounts.ensureIndex({type: 'hash', fields: ['host'], unique: true})
db.accounts.ensureIndex({type: 'hash', fields: ['database'], unique: true})

*/
