const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//

exports.addNumMembers = functions.firestore
    .document('contributor/{queueId}/members/{uid}')
    .onCreate((snap, context) => {
    
    const queueId = context.params.queueId;
    
    db.collection('location').doc(queueId).set({
        numMembers: admin.firestore.FieldValue.increment(1)
    }, {merge: true})
    .then( () => {
        return;
    })

    });

exports.removeNumMembers = functions.firestore
    .document('contributor/{queueId}/members/{uid}')
    .onDelete((snap, context) => {
    
    const queueId = context.params.queueId;
    
    db.collection('location').doc(queueId).set({
        numMembers: admin.firestore.FieldValue.increment(-1)
    }, {merge: true})
    .then( () => {
        return;
    })

    });
        
        

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
                db.collection('playlist').doc(queueId).collection('songs').doc(songId).set({
                    votes: admin.firestore.FieldValue.increment(1)
                }, {merge: true})
                .then( () => {
                    return;
                })
            }
            else {
                var isDup = false;
                snapshot.forEach(doc => {
                    if (doc.id == uid) {
                        isDup = true;
                    }
                });
                if (isDup) {
                    db.collection('song').doc(songId).collection('downvoteUsers').doc(uid).delete()
                    db.collection('playlist').doc(queueId).collection('songs').doc(songId).set({
                        votes: admin.firestore.FieldValue.increment(2)
                    }, {merge: true})
                    .then( () => {
                        return;
                    })
                }
                else {
                    db.collection('playlist').doc(queueId).collection('songs').doc(songId).set({
                        votes: admin.firestore.FieldValue.increment(1)
                    }, {merge: true})
                    .then( () => {
                        return;
                    })
                    
                }
            }
            
        })
    })

    });

    exports.updateDownvotes = functions.firestore
    .document('song/{songId}/downvoteUsers/{uid}')
    .onCreate((snap, context) => {

    const songId = context.params.songId;
    const uid = context.params.uid;

    db.collection('song').doc(songId).get()
    .then(doc => {
        const queueId = doc.data().queueId
        db.collection('song').doc(songId).collection('upvoteUsers').get()
        .then(snapshot => {
            if (snapshot.empty) {
                db.collection('playlist').doc(queueId).collection('songs').doc(songId).set({
                    votes: admin.firestore.FieldValue.increment(-1)
                }, {merge: true})
                .then( () => {
                    return;
                })
            }
            else {
                var isDup = false;
                snapshot.forEach(doc => {
                    if (doc.id == uid) {
                        isDup = true;
                    }
                });
                if (isDup) {
                    db.collection('song').doc(songId).collection('upvoteUsers').doc(uid).delete()
                    db.collection('playlist').doc(queueId).collection('songs').doc(songId).set({
                        votes: admin.firestore.FieldValue.increment(-2)
                    }, {merge: true})
                    .then( () => {
                        return;
                    })
                }
                else {
                    db.collection('playlist').doc(queueId).collection('songs').doc(songId).set({
                        votes: admin.firestore.FieldValue.increment(-1)
                    }, {merge: true})
                    .then( () => {
                        return;
                    })
                    
                }
            }
            
        })
    })

    });
