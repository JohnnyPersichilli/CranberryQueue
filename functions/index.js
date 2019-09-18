const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//

exports.updateNetVotes = functions.firestore
    .document('song/{songId}/upvoteUsers/{uid}')
    .onCreate((snap, context) => {

    const songId = context.params.songId;
    const uid = context.params.uid;

    db.collection('song').doc(songId).get()
    .then(doc => {
        const queueId = doc.data().queueId
        db.collection('song').doc(songId).collection('downvoteUsers').get()
        .then(snapshot => {
            if (snapshot.empty) {
                return;
            }
            var isDup = false;
            snapshot.forEach(doc => {
                if (doc.id == uid) {
                    isDup = false;
                }
            });
            if (isDup) {
                db.collection('song').doc(songId).collection('downvoteUsers').doc(uid).delete()
                .then( val => {

                })
            }
            else {
                db.collection('song').doc(songId).collection('upvoteUsers').get()
                    .then(snap => {
                        const netvotes = snap.length - snapshot.length;
                    db.collection('playlist').doc(queueId).collection('songs').doc(songId).set({
                        votes: netvotes
                    }, {merge: true})
                })
                
            }
        })
    })

    });
