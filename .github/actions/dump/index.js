const github = require( '@actions/github' );

console.log( JSON.stringify( github.context, null, 4 ) );
