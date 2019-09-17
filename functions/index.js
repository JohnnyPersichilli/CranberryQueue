const functions = require('firebase-functions');

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//

exports.updateNetVotes = functions.firestore
    .document('songs/{songId}/upvoteUsers/{uid}')
    .onUpdate((change, context) => {
      // Get an object representing the document
      // e.g. {'name': 'Marie', 'age': 66}
      const newValue = change.after.data();
      console.log(newValue)

      // ...or the previous value before this update
      const previousValue = change.before.data();
      console.log(previousValue)

      // access a particular field as you would any JS property
      const name = newValue.name;

      // perform desired operations ...
    });
