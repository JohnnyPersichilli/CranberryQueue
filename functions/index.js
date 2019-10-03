const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions


//general garbage cleanup fn
exports.deleteLocation = functions.firestore
    .document('location/{locationId}')
    .onDelete((snap, context) => {

        const queueId = context.params.locationId

        //remove subcollection in contributor, so its not orphaned
        db.collection('contributor').doc(queueId).collection('members').get().then((querySnapshot) => {
            // this will actually trigger the other onDelete listener, so we need to set a global boolean to ignore that update
            querySnapshot.forEach((doc) => {
                doc.ref.delete()
            })
        }).then(() => {
            //delete the contributor doc after
            // console.log("contributor table: " + locationId + " successfully deleted")
            db.collection('contributor').doc(queueId).delete()

        })

        //delete the playback doc
        db.collection('playback').doc(queueId).delete().then(() => {
            // console.log("playback table: " + queueId + " successfully deleted")
        })

        //deleting songs from the playlist song table so not orphaned
        db.collection('playlist').doc(queueId).collection('songs').get().then((querySnapshot) => {
            querySnapshot.forEach((doc) => {
                //now delete the song out of the 
                doc.ref.delete()
            })
        }).then(() => {
            // console.log("successfully deleted playlist " + queueId + " table")
            db.collection('playlist').doc(queueId).delete()
        })

        // delete songs from song table
        db.collection('song').where("queueId", "==", queueId).get()
        .then((querySnapshot) => {
            querySnapshot.forEach((doc) => {
                //in each song object, we need to remove all entries from upvote users and downvote userse
                doc.ref.collection('upvoteUsers').get().then((querySnapshot) => {
                    querySnapshot.forEach((doc) => {
                        doc.ref.delete()
                    })
                }).then(() => {
                    doc.ref.collection('downvoteUsers').get().then((querySnapshot) => {
                        querySnapshot.forEach((doc) => {
                            doc.ref.delete()
                        })
                    })
                }).then(() => {
                    //finally, delete the song obj
                    doc.ref.delete()
                })
            })
        })

    })

exports.addNumMembers = functions.firestore
    .document('contributor/{queueId}/members/{uid}')
    .onCreate((snap, context) => {
    
    const queueId = context.params.queueId;
    
    db.collection('location').doc(queueId).update({
        numMembers: admin.firestore.FieldValue.increment(1)
    }, {merge: true})
    .then( () => {
        return;
    })
});


exports.removeFromMembers = functions.https.onRequest((request, response) => {
    if(request.method !== 'PUT') {
        return response.status(403).send('Forbidden!');
    }
    let queueId = request.body.queueId
    let uid = request.body.uid

    //delete the uid from contributor-members collection
    db.collection('contributor').doc(queueId).collection('members').doc(uid).delete()

    //decrement the numMembers from location collection
    db.collection('location').doc(queueId).update({
        numMembers: admin.firestore.FieldValue.increment(-1)
    }, {merge: true})
    .then( () => {
        response.status(200).send('success');
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
                db.collection('playlist').doc(queueId).collection('songs').doc(songId).update({
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
                    db.collection('playlist').doc(queueId).collection('songs').doc(songId).update({
                        votes: admin.firestore.FieldValue.increment(2)
                    }, {merge: true})
                    .then( () => {
                        return;
                    })
                }
                else {
                    db.collection('playlist').doc(queueId).collection('songs').doc(songId).update({
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
                db.collection('playlist').doc(queueId).collection('songs').doc(songId).update({
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
                    db.collection('playlist').doc(queueId).collection('songs').doc(songId).update({
                        votes: admin.firestore.FieldValue.increment(-2)
                    }, {merge: true})
                    .then( () => {
                        return;
                    })
                }
                else {
                    db.collection('playlist').doc(queueId).collection('songs').doc(songId).update({
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
